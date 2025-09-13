# 仕様書

## 1. 目的

GitHub Actionsワークフロー `.github/workflows/auto-pr.yml` が、Issueの作成をトリガーとして期待通りに動作することを検証する。

## 2. 背景

プロジェクトでは、Issueが作成された際に、仕様・計画の策定、フィーチャーブランチの作成、Pull Requestの作成といった一連のプロセスを自動化するために `auto-pr.yml` を導入している。この自動化ワークフローが、実際の運用において設計通りに機能するかを確認する必要がある。

## 3. 検証対象と期待される動作

### 3.1. ワークフローのトリガー
- **対象:** `auto-pr.yml` の `on.issues.types: [opened]` トリガー
- **期待される動作:** 新規にIssueを作成した際、`Plan and Implement on Issue` ワークフローが自動的に実行されること。

### 3.2. 仕様・計画ファイルの自動生成
- **対象:** `plan` ジョブ内の `Create Plan with Gemini` ステップ
- **期待される動作:**
    - `specs/` ディレクトリ配下に、Issue番号を含む新しいディレクトリ（例: `specs/094-auto-pr-workflow-test`）が作成されること。
    - 作成されたディレクトリ内に、Issueの内容を反映した `spec.md`, `plan.md`, `tasks.md` が生成されること。

### 3.3. フィーチャーブランチの作成とプッシュ
- **対象:** `plan` ジョブ内の `Commit & push spec/plan/tasks` ステップ
- **期待される動作:**
    - `spec.md` に記載された、あるいはデフォルトの命名規則（`feature/issue-{issue_number}`）に従った名前で、新しいブランチが作成されること。
    - 自動生成された仕様・計画ファイル群が、そのブランチにコミットされ、リモートリポジトリにプッシュされること。

### 3.4. Pull Requestの自動作成
- **対象:** `plan` ジョブ内の `Create PR for Spec/Plan` ステップ
- **期待される動作:**
    - 作成されたフィーチャーブランチから `main` ブランチへ向けて、Pull Requestが自動的に作成されること。
    - Pull Requestのタイトルと本文が、Issue番号を含む適切な内容で自動設定されていること。
    - `spec-kit`, `plan` ラベルが付与されていること。

## 4. 検証の範囲外
- `auto-pr.yml` ファイル自体のコード修正は行わない。
- `workflow_dispatch` やコメント作成によるトリガーの検証は、今回は範囲外とする。

## 5. 成果物
- 検証手順と結果をまとめたドキュメント。
