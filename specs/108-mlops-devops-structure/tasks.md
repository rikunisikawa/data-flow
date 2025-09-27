# タスクリスト: MLOps/DevOps 導入

### Task 1: CI の下地整備（設計）
- 説明: dbt/pytest/Lint/TypeCheck の実行順序・条件を定義（ワークフローファイルは別PR）
- 成果物: `ai-doc/operations/workflow-usage.md` 更新案
- 検証: 設計レビュー合意

### Task 2: IAM/OIDC ロール用 Terraform
- 説明: GitHub Actions 用の OIDC IAM ロールと最小権限ポリシーを作成
- 成果物: `terraform` 変更
- 検証: `aws sts assume-role-with-web-identity` シミュレーション成功

### Task 3: モデル成果物の版管理方式
- 説明: S3 パス命名（`models/YYYYMMDD-HHMM/<name>-<semver>/`）とメトリクス JSON のスキーマ定義
- 成果物: `ai-doc/infra/system_design.md` 追記
- 検証: サンプル成果物で確認

### Task 4: 監視/可観測性
- 説明: CloudWatch Logs Insights のクエリ雛形、メトリクス/アラーム（失敗回数/実行時間）
- 成果物: ダッシュボード/クエリ記載
- 検証: ダッシュボードで可視化

### Task 5: リリース運用ルール
- 説明: ブランチ/タグ/バージョニングのルールを定義（SemVer、環境毎の命名）
- 成果物: `ai-doc/operations/workflow-usage.md` 追記
- 検証: ルールに従いタグ付与/反映テスト

---
