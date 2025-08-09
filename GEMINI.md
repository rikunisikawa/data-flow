# ✅ AIコーディング最適化指示書

## 📖 概要

このドキュメントは、AI（Gemini）がこのプロジェクトで開発を行う際の指示書です。

## 📚 ドキュメント構造

プロジェクトのドキュメントは、`.github/docs/` ディレクトリ以下に種類別に整理されています。

- **GitHub Actions**: `.github/docs/github-actions/`
  - `auto-pr-workflow.md`: Issue起票からPull Request作成までの自動化ワークフローに関する仕様。
  - `terraform-deploy-workflow.md`: Terraformによるインフラデプロイ自動化ワークフローに関する仕様。
  - `github-actions-iam-role-auth.md`: GitHub ActionsでのIAMロール認証（OpenID Connect）の設定方法。

- **システム設計**: `ai-doc/infra/`
  - `terraform-design.md`: Terraformを用いたインフラストラクチャ管理の設計思想と運用方針。
  - その他のシステム設計ドキュメント。

- **Gemini CLI ログ**: `.github/docs/gemini-cli-logs/`
  - Gemini CLIの実行ログや、特定のタスクに関するメモが日付ごとに保存されます。

## 🤖 開発フロー

このプロジェクトでは、GitHub Actionsにより、Issue起票からPull Requestのマージ準備までが半自動化されています。詳細については、`.github/docs/github-actions/auto-pr-workflow.md` を参照してください。

### プロジェクト計画

手動で作成された、プロジェクトの大きな方向性やフェーズを示す計画書は、`ai-doc/project-plans/` に保存されます。

## 📝 開発ルール

- **指示と進捗の記録**:
  - 指示内容、変更履歴、進捗は `.github/` ディレクトリにMarkdownファイル（`.md`）として保存します。
  - ファイル名は `YYYYMMDD_description.md` の形式とします。（例: `20250727_improve_gemini_md.md`）

- **テストコード**:
  - Pythonコードを新規作成または変更する場合は、必ず関連するテストコードを `tests/` ディリクトリに作成・更新してください。
  - テストは `pytest` を使用して実行可能である必要があります。

## 🚀 Pull Requestとコミット

- **Pull Request**:
  - 作成するPull Requestのタイトルには、**必ず対応するIssue番号を含めてください**。（例: `feat: 新機能の追加 (issue #17)`）
  - 本文には、**変更内容の全体像がわかるようなサマリー**を記述してください。どのような背景で、何を、どのように変更したのかが他の開発者に伝わるようにまとめてください。

- **コミット**:
  - コミットは、**機能単位や意味のあるまとまり**で行ってください。例えば、「認証機能の追加」「バグ修正: ログイン画面の表示崩れ」のように、一つの変更内容が一つのコミットになるようにしてください。
  - 関連性のない複数の変更を一つのコミットに含めないでください。

## ⚠️ 禁止事項

- `.github/workflows` ディレクトリ内のファイルは、ワークフローのコア機能に影響を与えるため、**絶対に編集しないでください**。
