# Issue #78: GitHub ActionsにSpec Kitを導入するための実装計画

## 1. 概要

本計画は、Issue #78で提案された、Spec Kitを活用した仕様駆動開発（Spec-Driven Development）を自動化するGitHub Actionsワークフローを導入するための実装計画を定義します。

Issueで提供されたYAML定義に基づき、Issue起票から仕様・計画の策定、そして実装までを半自動化する新しいワークフローを構築します。

## 2. 実装方針

- **ワークフローファイルの新規作成**:
  - 既存のワークフロー（`.github/workflows/`内のファイル）は変更せず、新しいワークフローファイルとして `.github/workflows/spec-driven-development.yml` を作成します。これにより、既存のCI/CDプロセスへの影響を避けつつ、新機能を追加します。
- **Issue提供のYAMLをベースに採用**:
  - Issueに記載されているワークフロー定義をほぼそのまま採用します。ただし、一部のアクション参照に修正が必要な箇所は、適切な形式に修正します。
- **前提条件の明確化**:
  - ワークフローが正常に動作するために必要なシークレット（`GEMINI_API_KEY`）について、リポジトリに設定されている必要があることを明記します。

## 3. 作業タスク

### 3.1. ワークフローファイルの作成

新しいGitHub Actionsワークフローファイルを以下の仕様で作成します。

- **ファイルパス**: `/home/runner/work/data-flow/data-flow/.github/workflows/spec-driven-development.yml`
- **内容**:
  - Issueで提供されたYAML定義を基に作成します。
  - `uses: google-gemini/gemini-cli-action@terraform/main.tf` という参照は、GitHub Actionsの標準的な参照形式ではないため、より一般的で動作可能性の高い `google-gemini/gemini-cli-action@main` に修正します。これは、アクションのmainブランチを追跡することを意味します。

```yaml
name: "Spec-Driven Plan and Implement"

on:
  workflow_dispatch:
  issues:
    types: [opened]
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]

jobs:
  setup_spec_kit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - name: Install uv (for specify CLI)
        run: |
          curl -LsSf https://astral.sh/uv/install.sh | sh
          echo "${HOME}/.local/bin" >> $GITHUB_PATH
      - name: Bootstrap Spec Kit templates if missing (idempotent)
        run: |
          set -euo pipefail
          if [ ! -d "templates" ] || [ ! -d "scripts" ]; then
            uvx --from git+https://github.com/github/spec-kit.git specify init --here --ai gemini --ignore-agent-tools
          else
            echo "Spec Kit templates already present."
          fi

  plan:
    needs: setup_spec_kit
    if: github.event_name == 'issues' && github.event.action == 'opened'
    runs-on: ubuntu-latest
    permissions:
      contents: write
      issues: write
      pull-requests: write
    env:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - name: Specify (and optionally plan/tasks) with Gemini via Spec Kit
        id: gemini_specify
        uses: google-gemini/gemini-cli-action@main
        with:
          GEMINI_API_KEY: ${{ env.GEMINI_API_KEY }}
          prompt: |
            /background あなたはSpec Kitのガイドラインに従う上級プロジェクトマネージャ兼ソフトウェアエンジニアです。
            /background 以下のIssueをもとに新しい「機能」を開始してください。/specify により仕様を生成し、Spec Kit のスクリプトでブランチと specs ディレクトリを作成してください。
            /background その後 /plan を実行し、必要なら /tasks まで進めてください（tasks は後ででも可）。Geminiのファイル/シェルツールを使って必要なファイルを保存してください。
            /background 禁止事項: `.github/workflows` 配下は編集しない。run_shell_command で `$()`, `<()>`, `()>` のようなコマンド置換は使用しない。
            /specify
            [Feature] issue #${{ github.event.issue.number }}: ${{ github.event.issue.title }}
            [Context]
            ${{ github.event.issue.body }}
            /plan この機能は既存レポジトリに段階的に追加します。現行のスタック/規約と整合し、テスト方針と影響範囲も含めて計画してください。
      - name: Detect latest spec branch and dir
        id: detect_spec
        run: |
          set -euo pipefail
          SPEC_DIR="$(ls -1d specs/* 2>/dev/null | sort | tail -n1 || true)"
          if [ -z "${SPEC_DIR}" ]; then
            echo "No specs directory created." >&2
            exit 1
          fi
          BRANCH_NAME="$(grep -m1 -E '^Feature Branch:' "${SPEC_DIR}/spec.md" | sed -E 's/.*`([^`]+)`.*/\1/')"
          if [ -z "${BRANCH_NAME}" ]; then
            echo "Could not parse Feature Branch from ${SPEC_DIR}/spec.md" >&2
            exit 1
          fi
          echo "spec_dir=${SPEC_DIR}" >> "$GITHUB_OUTPUT"
          echo "branch_name=${BRANCH_NAME}" >> "$GITHUB_OUTPUT"
      - name: Commit & push spec/plan/tasks
        run: |
          set -euo pipefail
          git config user.name "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git switch -c "${{ steps.detect_spec.outputs.branch_name }}" || git switch "${{ steps.detect_spec.outputs.branch_name }}"
          if [ -n "$(git status --porcelain)" ]; then
            git add -A
            git commit -m "spec: initialize ${{ steps.detect_spec.outputs.branch_name }} for issue #${{ github.event.issue.number }}"
          fi
          git push -u origin "${{ steps.detect_spec.outputs.branch_name }}"
      - name: Create PR for Spec/Plan
        run: |
          set -euo pipefail
          BR="${{ steps.detect_spec.outputs.branch_name }}"
          BODY_FILE="$(mktemp)"
          {
            echo "This PR bootstraps Spec/Plan for **issue #${{ github.event.issue.number }}** using Spec Kit."
            echo
            echo "- Spec dir: \"`${{ steps.detect_spec.outputs.spec_dir }}`\""
            echo "- Branch: \"`BR`\""
            echo
            echo "次のステップ: 追記や修正はコメントで。実装を進める場合は Issue や PR に **/execute** とコメントしてください。"
          } > "$BODY_FILE"
          if gh pr view "$BR" --json number -q .number >/dev/null 2>&1; then
            gh pr edit "$BR" --title "Spec: ${BR} for issue #${{ github.event.issue.number }}" --body-file "$BODY_FILE"
          else
            gh pr create \
              --title "Spec: ${BR} for issue #${{ github.event.issue.number }}" \
              --body-file "$BODY_FILE" \
              --base main \
              --head "$BR" \
              --label "spec-kit,plan"
          fi

  implement:
    needs: [setup_spec_kit]
    if: contains(github.event.comment.body, '/execute')
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    env:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - name: Resolve PR/branch for the /execute trigger
        id: resolve_branch
        run: |
          set -euo pipefail
          EVENT="${{ github.event_name }}"
          if [ "$EVENT" = "pull_request_review_comment" ]; then
            PR=${{ github.event.pull_request.number }}
          elif [ -n "${{ github.event.issue.pull_request }}" ]; then
            PR=${{ github.event.issue.number }}
          else
            echo "This /execute must be used on a PR (for spec-kit implement)."
            exit 1
          fi
          BRANCH_NAME="$(gh pr view "$PR" --json headRefName -q .headRefName)"
          echo "branch_name=$BRANCH_NAME" >> "$GITHUB_OUTPUT"
      - name: Checkout feature branch
        uses: actions/checkout@v4
        with:
          ref: ${{ steps.resolve_branch.outputs.branch_name }}
          fetch-depth: 0
      - name: Locate plan.md for this feature
        id: find_plan
        run: |
          set -euo pipefail
          SPEC_DIR="$(ls -1d specs/* 2>/dev/null | sort | tail -n1 || true)"
          if [ -z "${SPEC_DIR}" ]; then
            echo "No specs dir found." >&2; exit 1
          fi
          PLAN="${SPEC_DIR}/plan.md"
          if [ ! -f "$PLAN" ]; then
            echo "plan.md not found at $PLAN" >&2; exit 1
          fi
          echo "spec_dir=$SPEC_DIR" >> "$GITHUB_OUTPUT"
          echo "plan=$PLAN" >> "$GITHUB_OUTPUT"
      - name: Implement with Gemini (Spec Kit)
        id: gemini_implement
        uses: google-gemini/gemini-cli-action@main
        with:
          GEMINI_API_KEY: ${{ env.GEMINI_API_KEY }}
          prompt: |
            /background あなたはプロのソフトウェアエンジニアです。Spec Kit で作成された計画に従い、このPRブランチに必要な全コードを実装してください。
            /background 禁止事項: `.github/workflows` は編集しない。run_shell_command での `$()`, `<()>`, `()>` は使わない。
            /background 参考: 最新コメントは以下。要件に反映してください。
            ${{ github.event.comment.body }}
            次を実行してください:
            implement ${{ steps.find_plan.outputs.plan }}
            ---PR_TITLE---
            feat: implement ${{ steps.resolve_branch.outputs.branch_name }}
            ---PR_BODY---
            このPRは Spec Kit の計画 (`${{ steps.find_plan.outputs.plan }}`) に基づき自動実装を行いました。
            変更概要・影響範囲・テスト観点を記載し、必要ならタスクの残項目を列挙してください。
            ---COMMIT_MESSAGE---
            feat: implement according to spec-kit plan
      - name: Extract PR info
        id: extract_pr
        env:
          RESULT: ${{ steps.gemini_implement.outputs.result }}
        run: |
          set -euo pipefail
          pr_title="$(printf '%s\n' "$RESULT" | awk '/---PR_TITLE---/{flag=1;next}/---PR_BODY---/{flag=0}flag' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
          pr_body="$(printf '%s\n' "$RESULT" | awk '/---PR_BODY---/{flag=1;next}/---COMMIT_MESSAGE---/{flag=0}flag')"
          commit_msg="$(printf '%s\n' "$RESULT" | awk '/---COMMIT_MESSAGE---/{flag=1;next}flag')"
          [ -z "$pr_title" ] && pr_title="feat: implement ${{ steps.resolve_branch.outputs.branch_name }}"
          [ -z "$pr_body" ] && pr_body="Auto-implemented via Spec Kit plan."
          [ -z "$commit_msg" ] && commit_msg="feat: implement via spec-kit"
          {
            echo "title<<EOF"; echo "$pr_title"; echo "EOF";
            echo "body<<EOF"; echo "$pr_body"; echo "EOF";
            echo "commit<<EOF"; echo "$commit_msg"; echo "EOF";
          } >> "$GITHUB_OUTPUT"
      - name: Commit & push changes
        run: |
          set -euo pipefail
          git config user.name "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          if [ -n "$(git status --porcelain)" ]; then
            git add -A
            git commit -m "${{ steps.extract_pr.outputs.commit }}"
            git push
          else
            echo "No changes to commit."
          fi
      - name: Open or update PR
        run: |
          set -euo pipefail
          BR="${{ steps.resolve_branch.outputs.branch_name }}"
          BODY_FILE="$(mktemp)"; printf '%s' "${{ steps.extract_pr.outputs.body }}" > "$BODY_FILE"
          if gh pr view "$BR" --json number -q .number >/dev/null 2>&1; then
            gh pr edit "$BR" --title "${{ steps.extract_pr.outputs.title }}" --body-file "$BODY_FILE"
          else
            gh pr create --title "${{ steps.extract_pr.outputs.title }}" --body-file "$BODY_FILE" --base main --head "$BR"
          fi
```

## 4. 前提条件

- 本ワークフローは `GEMINI_API_KEY` を使用してGemini APIと通信します。事前にリポジトリの `Settings > Secrets and variables > Actions` で `GEMINI_API_KEY` を登録しておく必要があります。

## 5. 今後のステップ

本計画にご承認いただけましたら、上記内容で `.github/workflows/spec-driven-development.yml` を作成します。
