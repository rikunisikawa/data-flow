# GitHub Actions: 自動Pull Requestワークフロー

## 概要

このドキュメントは、AI（Gemini）がこのプロジェクトで開発を行う際の指示書の一部として、GitHub Actionsによる自動Pull Requestワークフローについて説明します。

## 開発フロー

このプロジェクトでは、GitHub Actionsにより、Issue起票からPull Requestのマージ準備までが半自動化されています。

1.  **Issueの起票**: すべての開発タスクはIssueとして開始されます。

2.  **計画 (Plan)**: Issueが作成されると、GitHub Actionsが自動で起動します。
    - GeminiがIssueの内容を分析し、実装計画を作成します。
    - `feature/issue-XXX` という名前のブランチが作成され、計画レビューのための **Pull Requestが自動で起票されます**。

3.  **実行 (Implement)**: プロジェクト関係者がPull Request上で計画を確認し、承認できる場合は、**対応するIssue**のコメント欄に `/execute` と入力します。（追加の指示もコメントに含めることが可能です）

4.  **実装とPR更新 (Update Pull Request)**: `/execute` コメントをトリガーに、GitHub Actionsが再度起動します。
    - Geminiが計画と追加指示に基づき、実装を行います。
    - 完了後、**ステップ2で作成されたPull Requestが、自動的に実装内容で更新されます**。

5.  **レビューとマージ**: 自動更新されたPull Requestを最終レビューし、問題がなければマージします。

## 禁止事項

- `.github/workflows` ディレクトリ内のファイルは、ワークフローのコア機能に影響を与えるため、**絶対に編集しないでください**。
