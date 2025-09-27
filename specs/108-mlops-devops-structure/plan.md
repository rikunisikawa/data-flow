# 計画: MLOps/DevOps の導入（データ/モデルのCI/CDと可観測性）

**Branch**: `108-mlops-devops-structure` | **Owner**: Platform | **Date**: 2025-09-27

## 目的
- データ/コード/モデルの変更を一貫したパイプラインで管理し、品質ゲート（テスト/スタイル/セキュリティ）とデプロイ自動化を導入。

## スコープ
- CI: dbt の `run/test`、Python の `pytest`、Lint/TypeCheck を PR で実施。
- CD: Terraform の plan/apply、ECR へのイメージ push、Step Functions 構成更新の自動化（本番は承認付き）。
- 可観測性: CloudWatch Logs/メトリクス、実行履歴のダッシュボード化。
- レジストリ: モデル成果物（S3バージョン付け）とメタデータ管理（簡易レジストリ or MLflow 検討）。

## 方針
- GitHub Actions は OIDC + IAM ロール引受を用い、最小権限化（AGENTS.md に準拠、直接編集は別途レビュー経由）。
- 変更種別（app/infra/model）ごとにワークフローを分離し、並列化。
- 品質ゲート: dbt tests/data tests を必須。モデルコードは単体テストと静的検査を必須。

## DoD
- PR 時に CI が実行され、dbt test/pytest が必ず走る。
- main マージで dev 環境へ自動デプロイ。本番は手動承認を挟む。
- モデル成果物のバージョンが S3 で追跡可能（メトリクスJSONと紐付け）。

---
