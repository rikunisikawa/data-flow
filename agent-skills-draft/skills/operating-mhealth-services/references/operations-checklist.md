# 運用チェックリスト

## デプロイ手順
1. `build.sh <env>` を実行して Lambda/Layer の成果物を作成し S3 へアップロードする。
2. dbt のイメージタグが `terraform/<env>.tfvars` の `dbt_image_tag` と一致しているか確認する。
3. `dev`/`prod` の workspace を明示して Terraform を実行する。

## dbt 実行
- `data_flow_dbt/scripts/with-env.sh` または Docker（`docker/dbt/docker compose.yml`）を優先する。
- 必須環境変数を確認する: `S3_STAGING_DIR`, `S3_DATA_DIR`, `AWS_REGION`, `GLUE_DATABASE`, `DBT_SCHEMA`, `ATHENA_WORK_GROUP`。

## 運用メモ
- `terraform-deploy-workflow-change-proposal.md` は未実装の提案として扱う。
- デプロイや実行手順に影響する変更には簡単なロールバックメモを残す。
