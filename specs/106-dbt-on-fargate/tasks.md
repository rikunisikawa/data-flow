# タスクリスト: dbt on Fargate + Step Functions 統合

### Task 1: ECR リポジトリ作成
- 説明: `data-platform/dbt` リポジトリを Terraform で作成。
- 成果物: `terraform/modules/ecr_dbt/` or 直下定義、`terraform` 変更差分。
- 検証: `aws ecr describe-repositories` で存在確認。

### Task 2: イメージビルド/プッシュ経路
- 説明: 既存 `docker/dbt/Dockerfile` を ECR に push。初期は手動、後にCI化。
- 成果物: 手順メモ（ai-doc 追記）。
- 検証: `ECR <account>.dkr.ecr.../dbt:<tag>` 参照可能。

### Task 3: ECS/Fargate 基盤（Terraform）
- 説明: クラスター/タスク定義/タスクロール/実行ロール/CloudWatch Logs/VPC設定を追加。
- 成果物: `terraform` 変更一式。
- 検証: `RunTask` 単体実行で `dbt --version` 成功。

### Task 4: Step Functions 統合
- 説明: ASL に `RunTask` ステップを追加し、`Download→Convert→dbt` の直列実行を実現。
- 成果物: `state_machine/*.json` と Terraform の参照更新。
- 検証: dev ワークスペースで実行完了。

### Task 5: 権限スコープダウン
- 説明: S3/Athena/Glue へのアクセスを最小権限化（バケット/DB/リージョンの限定）。
- 成果物: IAM ポリシー。
- 検証: 余計な権限がないことを IAM アクセスアドバイザーで確認。

### Task 6: ドキュメント更新
- 説明: `ai-doc/infra/system_design.md` と `dbt_athena_setup.md` に Fargate 実行を追記。
- 成果物: ドキュメント更新PR。
- 検証: 記載手順で再現可能。

---
