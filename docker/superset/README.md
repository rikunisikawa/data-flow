# Apache Superset (Local)

本ディレクトリは、Apache Superset をローカルで起動するための構成一式です。
Superset は可視化専用で運用し、ビジネスロジックは dbt を Single Source of Truth とします。

## 前提

- Docker / Docker Compose が利用可能であること
- Athena と Glue Data Catalog への Read Only 権限を持つ IAM ユーザーがあること

## セットアップ

1. 環境変数を用意します。
   - Superset 用の認証情報と `SUPERSET_SECRET_KEY` は SSM Parameter Store で管理します。
   - ローカル実行時は `aws ssm get-parameter` で取得して環境変数にセットします。

例（dev workspace）:

```bash
export AWS_ACCESS_KEY_ID=$(aws ssm get-parameter \
  --name "/data-flow/dev/superset/athena/access_key_id" \
  --with-decryption --query "Parameter.Value" --output text)
export AWS_SECRET_ACCESS_KEY=$(aws ssm get-parameter \
  --name "/data-flow/dev/superset/athena/secret_access_key" \
  --with-decryption --query "Parameter.Value" --output text)
export SUPERSET_SECRET_KEY=$(aws ssm get-parameter \
  --name "/data-flow/dev/superset/secret_key" \
  --with-decryption --query "Parameter.Value" --output text)

export AWS_REGION=ap-northeast-1
export SUPERSET_ADMIN_USERNAME=admin
export SUPERSET_ADMIN_PASSWORD=admin
export SUPERSET_ADMIN_EMAIL=admin@example.com
```

2. Superset を起動します。

```bash
cd docker/superset
docker compose up -d superset-db superset-redis
docker compose up -d superset
```

### SSM パラメータ

Terraform で以下を作成します（workspace 名を含むパス）。

- `/data-flow/<workspace>/superset/athena/access_key_id`
- `/data-flow/<workspace>/superset/athena/secret_access_key`
- `/data-flow/<workspace>/superset/secret_key`

3. 初期化と管理ユーザー作成を行います。

```bash
docker compose run --rm superset-init
```

4. ブラウザで `http://localhost:8088` にアクセスし、管理ユーザーでログインします。

## Athena 接続

Superset UI から以下を設定します。

1. `Data` -> `Databases` -> `+ Database`
2. `SQLAlchemy URI` を以下の形式で入力

```
awsathena+rest://{aws_access_key_id}:{aws_secret_access_key}@athena.{region}.amazonaws.com:443/{schema}?s3_staging_dir={s3_staging_dir}
```

例:

```
awsathena+rest://AKIA...:SECRET...@athena.ap-northeast-1.amazonaws.com:443/processed?s3_staging_dir=s3://your-query-results-bucket/prefix/
```

3. `Test Connection` を実行して接続を確認

## Dataset 登録と可視化

- `Data` -> `Datasets` で dbt Gold 層テーブルを登録します。
- Silver / Bronze 層は登録しません。
- KPI や集計ロジックは dbt 側で定義し、Superset 側では追加の SQL を書きません。

## 運用メモ

- Superset は read-only で利用します（書き込みや更新はしません）。
- 設定は `docker/superset/superset_config.py` に集約しています。
- Athena への権限は最小権限（Glue と S3 の読み取りのみ）に限定してください。

## トラブルシュート

- 初期化に失敗する場合: `docker compose logs superset-init` を確認してください。
- ログインできない場合: `.env.dev` の `SUPERSET_ADMIN_*` を再確認し、`superset-init` を再実行してください。
