# タスクリスト

## 1. `auto-pr.yml` ワークフローの分析

-   **タスク:** `.github/workflows/auto-pr.yml` ファイルの内容を読み、トリガー条件、ジョブフロー、各ステップの処理内容を正確に理解する。
-   **成果物:** なし（担当者の理解を深めることが目的）。
-   **検証方法:** ワークフローの構造（トリガー、ブランチ作成ロジック、PR作成コマンドなど）を説明できる状態になること。

## 2. テスト用Issueの作成

-   **タスク:** `auto-pr.yml` の動作検証を目的とした、テスト用のIssueをGitHub上で作成する。
    -   **タイトル例:** `Test: auto-pr.yml workflow verification`
    -   **本文例:** `This is a test issue to verify the functionality of the auto-pr.yml workflow.`
-   **成果物:** GitHub Issue
-   **検証方法:** Issue作成後、[リポジトリのActionsタブ](https://github.com/owner/repo/actions)で `Plan and Implement on Issue` ワークフローが自動的に開始されることを確認する。

## 3. ワークフロー実行結果の確認

-   **タスク:** 実行されたワークフローの結果を多角的に確認する。
    1.  **Actionsログの確認:** ワークフローがエラーなく正常に完了したことをログで確認する。
    2.  **生成ファイルの確認:** `specs/` 配下に新しいディレクトリと `spec.md`, `plan.md`, `tasks.md` が生成されていることを確認する。
    3.  **ブランチの確認:** `feature/issue-{issue_number}-{issue_title}` の形式で新しいブランチがリモートにプッシュされていることを `git branch -r` やGitHubのUIで確認する。
    4.  **Pull Requestの確認:** 新しいブランチから `main` へのPull Requestが作成されており、タイトル、本文、ラベル (`spec-kit`, `plan`) が適切に設定されていることを確認する。
-   **成果物:** なし（確認作業）。
-   **検証方法:** 上記の確認項目すべてが、`spec.md`に定義した期待される動作と一致すること。

## 4. 検証結果の文書化

-   **タスク:** 上記の検証プロセスと結果をまとめたレポートを作成する。成功した点、問題点（もしあれば）を明確に記述する。
-   **成果物:** `specs/094-auto-pr-workflow-test/research.md` (調査・検証結果として)
-   **検証方法:** 作成されたドキュメントの内容が、実施した検証手順と結果を正確に反映していることをレビューする。
