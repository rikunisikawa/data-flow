# Issue-23: GitHub Actionsワークフローの修正計画

## 1. 概要

本計画は、Issue #23「GithubActionsワークフローの修正」に対応するための実装計画です。
現在のワークフローでは、Pull Request作成時に参照されるIssue番号がずれる問題が報告されています。
この問題を解決し、より堅牢なワークフローを構築することを目的とします。

## 2. 問題分析

**現状**:
`/execute` コメントによって実装ジョブがトリガーされた際、Pull Request（PR）に関連付けられたIssue番号が、意図したものより1つ大きい番号として扱われることがある。

**原因**:
現在のワークフロー (`.github/workflows/auto-pr.yml`) の `implement` ジョブは、トリガーとなったコメントがPR上にある場合、そのPRの **タイトル** から正規表現 (`#<番号>`) を使ってIssue番号を抽出しています。
この方法は、PRのタイトルが手動で変更されたり、予期せぬ形式になっている場合に、誤った番号を抽出する、あるいは抽出に失敗する脆弱性を持ちます。Issue番号が「1つ大きく」なるという現象は、PRのタイトルが何らかの理由でPR自身の番号（Issue番号+1であることが多い）を含むように変更された場合に発生する可能性があります。

## 3. 修正方針

依頼内容の「ISSUE作成時のトリガーでISSUE番号を渡して」という趣旨を汲み取り、PRタイトルへの依存をなくし、より信頼性の高い情報源からIssue番号を特定するようにワークフローを修正します。

具体的には、PRからIssue番号を特定するロジックを、**PRのタイトル** を見るのではなく、PRに紐づく **ブランチ名** (`feature/issue-XXX`) から抽出する方法に変更します。ブランチ名は `plan` ジョブによってIssue番号に基づいて自動生成されるため、タイトルよりも信頼性が高い情報源と言えます。

## 4. 修正対象ファイル

- `.github/workflows/auto-pr.yml`

## 5. 実装タスク

`implement` ジョブ内の `Determine issue number and branch name` (`id: get_branch`) ステップのスクリプトを以下のように修正します。

### 変更前のスクリプト

```bash
TARGET_NUMBER=${{ github.event.issue.number }}

if [[ -n "${{ github.event.issue.pull_request }}" ]]; then
  ISSUE_NUMBER=$(gh pr view "$TARGET_NUMBER" --json title -q .title | grep -oE '#[0-9]+' | tr -d '#')
  if [[ -z "$ISSUE_NUMBER" ]]; then
    echo "Could not extract issue number from PR title."
    exit 1
  fi
else
  ISSUE_NUMBER=$TARGET_NUMBER
fi

BRANCH_NAME="feature/issue-$ISSUE_NUMBER"
echo "branch_name=$BRANCH_NAME" >> $GITHUB_OUTPUT
echo "issue_number=$ISSUE_NUMBER" >> $GITHUB_OUTPUT
```

### 変更後のスクリプト

```bash
ISSUE_NUMBER=""
BRANCH_NAME=""

# コメントがPR上で行われた場合
if [[ -n "${{ github.event.issue.pull_request }}" ]]; then
  # PR番号からブランチ名を取得
  PR_NUMBER=${{ github.event.issue.number }}
  BRANCH_NAME=$(gh pr view "$PR_NUMBER" --json headRefName -q .headRefName)
  
  # ブランチ名からIssue番号を抽出 (例: feature/issue-123 -> 123)
  if [[ "$BRANCH_NAME" =~ ^feature/issue-([0-9]+)$ ]]; then
    ISSUE_NUMBER="${BASH_REMATCH[1]}"
  else
    echo "Could not extract issue number from branch name: $BRANCH_NAME"
    exit 1
  fi
# コメントがIssue上で直接行われた場合
else
  ISSUE_NUMBER=${{ github.event.issue.number }}
  BRANCH_NAME="feature/issue-$ISSUE_NUMBER"
fi

if [[ -z "$ISSUE_NUMBER" || -z "$BRANCH_NAME" ]]; then
  echo "Failed to determine issue number or branch name."
  exit 1
fi

echo "branch_name=$BRANCH_NAME" >> $GITHUB_OUTPUT
echo "issue_number=$ISSUE_NUMBER" >> $GITHUB_OUTPUT
```

### 修正のポイント

- **PRからの情報取得**: コメントがPR上でなされた場合 (`if` 節)、`gh pr view` を使ってPRのタイトル (`title`) ではなく、ブランチ名 (`headRefName`) を取得します。
- **堅牢な番号抽出**: 取得したブランチ名 (`feature/issue-XXX`) から、Bashの正規表現マッチング `[[ "$BRANCH_NAME" =~ ... ]]` を使ってIssue番号を安全に抽出します。これにより、PRタイトルが変更されても影響を受けなくなります。
- **Issueコメントの維持**: Issueに直接コメントされた場合 (`else` 節) は、これまで通り `github.event.issue.number` をIssue番号として使用する、シンプルで確実な方法を維持します。
- **エラーハンドリング**: 番号の抽出に失敗した場合や、変数が空の場合にスクリプトが異常終了するようにチェック処理を追加します。

## 6. 検証方法

1.  新しいIssueを作成する。
2.  `plan` ジョブが実行され、計画用のPR (`Plan: ...`) が自動で作成されることを確認する。
3.  作成されたPRのタイトルを手動で編集し、Issue番号の記述を削除・変更する。
4.  編集後のPR上で `/execute` とコメントする。
5.  `implement` ジョブがトリガーされ、PRのタイトルではなくブランチ名から正しいIssue番号を特定し、後続の処理（実装、コミット、PR更新）を正常に完了することを確認する。
