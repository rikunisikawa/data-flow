# 🧠 dbt 導入手順書（Athena + Glue 対応）

## 🌟 目的

KaggleHub経由で取得した mHealth データセットをETLし、 Glue Data Catalog経由でAthenaから分析可能にしたデータに対して dbtを用いて以下を実現する:

- SQLによる変換 (Transform)
- テストによるデータ品質保証
- ドキュメントとデータリネージの可視化

---

## 1️⃣ このリポジトリでの実行方法（Quick Start）

本プロジェクトでは、以下のどちらでも dbt を実行できます。

- ローカル実行（既存）: ラッパー `data_flow_dbt/scripts/with-env.sh` を使用。
- Docker実行（新規）: `docker/dbt/docker-compose.yml` を使用。

前提（共通）:
- ルートの `.env.dev`（または `.env`）で `S3_STAGING_DIR`/`S3_DATA_DIR`/`AWS_REGION`/`GLUE_STAGE_DATABASE`/`DBT_SCHEMA`/`ATHENA_WORK_GROUP` を設定。参照: `.env.dev`。
- プロファイルはリポジトリ同梱の `.dbt/profiles.yml` を使用（`DBT_PROFILES_DIR=/work/.dbt`）。

実行コマンド例:

【ローカル】
```bash
# 接続確認
./data_flow_dbt/scripts/with-env.sh dbt debug

# 実行 / テスト
./data_flow_dbt/scripts/with-env.sh dbt run -m cleaned_activities
./data_flow_dbt/scripts/with-env.sh dbt test -m cleaned_activities

# ドキュメント
./data_flow_dbt/scripts/with-env.sh dbt docs generate
./data_flow_dbt/scripts/with-env.sh dbt docs serve --port 8080 --no-browser
```

【Docker】
```bash
# ビルド
docker compose -f docker/dbt/docker-compose.yml build

# 常駐起動（コンテナ内で対話実行したい場合）
docker compose -f docker/dbt/docker-compose.yml up -d

# シェルに入る（作業ディレクトリ: /work/data_flow_dbt）
docker compose -f docker/dbt/docker-compose.yml exec dbt bash
# 例: コンテナ内での実行
dbt debug
dbt run -m cleaned_activities
dbt docs generate && dbt docs serve --host 0.0.0.0 --port 8080 --no-browser

# 実行 / テスト
docker compose -f docker/dbt/docker-compose.yml run --rm dbt run -m cleaned_activities
docker compose -f docker/dbt/docker-compose.yml run --rm dbt test -m cleaned_activities

# ドキュメント生成/配信
docker compose -f docker/dbt/docker-compose.yml run --rm dbt docs generate
docker compose -f docker/dbt/docker-compose.yml run --rm --service-ports dbt docs serve --host 0.0.0.0 --port 8080 --no-browser
# → ブラウザで http://localhost:8080
```

Note:
- Docker 実行時は、ホストの `~/.aws` をコンテナに read-only マウントして認証を利用します（SSO/プロファイルを含む）。
- 既存のローカル実行とDocker実行は併存可能です。
 - 常駐起動（up -d）ではコンテナは `sleep infinity` で待機します。`exec` で入り、`dbt` コマンドを実行してください。

---

## 2️⃣ 必要ツールのインストール（ローカルで実行する場合）

Python仮想環境を作成し、以下をインストール（Docker 実行のみの場合は不要）：

```bash
pip install dbt-core==1.8.* dbt-athena-community==1.8.*
```

---

## 3️⃣ プロジェクト初期化（参考）

```bash
dbt init data_flow_dbt
cd data_flow_dbt
```

選択肢：

- adapter: athena
- プロファイル名: data\_flow
- デフォルト構成でOK

---

## 4️⃣ profiles.yml の作成（参考）

```yaml
data_flow:
  target: dev
  outputs:
    dev:
      type: athena
      s3_staging_dir: s3://aws-data-platform-20250607/dbt-temp/
      region_name: ap-northeast-1
      schema: default
      database: awsdatacatalog
      work_group: primary
```

> 本リポジトリでは `.dbt/profiles.yml` を同梱し、環境変数で設定値を切り替えます。
> Athena のクエリ一時保存場所 `s3_staging_dir` は実在バケット/パスである必要があります。

---

## 5️⃣ ソーステーブルの定義（本リポジトリでは実装済み）

`models/src_mhealth.yml` を作成：

```yaml
version: 2

sources:
  - name: mhealth
    database: awsdatacatalog
    schema: default
    tables:
      - name: raw_activity
```

---

## 6️⃣ モデルの作成（本リポジトリでは実装済み）

`models/cleaned_activities.sql` を作成：

```sql
{{ config(materialized='table') }}

SELECT
  id,
  accel_x,
  accel_y,
  accel_z,
  timestamp
FROM {{ source('mhealth', 'raw_activity') }}
WHERE accel_x IS NOT NULL
```

---

## 7️⃣ テストの作成（本リポジトリでは実装済み）

`models/tests.yml` を作成：

```yaml
version: 2

models:
  - name: cleaned_activities
    columns:
      - name: id
        tests:
          - not_null
      - name: timestamp
        tests:
          - not_null
```

---

## 8️⃣ 実行コマンド（汎用）

```bash
# モデルの実行
$ dbt run

# テストの実行
$ dbt test

# SQL構文の解析
$ dbt compile

# ドキュメント生成
$ dbt docs generate

# ドキュメント+リネージ表示
$ dbt docs serve
```

---

## 9️⃣ Glue Catalog の事前準備（参考）

processed/ 配下にある Parquet データに対して下記 DDL をAthenaで実行：

```sql
CREATE EXTERNAL TABLE default.raw_activity (
  id string,
  timestamp timestamp,
  accel_x double,
  accel_y double,
  accel_z double
)
STORED AS PARQUET
LOCATION 's3://aws-data-platform-20250607/processed/';
```

---

## 🔟 CI/CD との連携

- GitHub Actions / GitLab CI などで `dbt run`, `dbt test` を自動実行
- Step Functions / Airflow などのワークフローでの実行も可

---

## ✅ 成果物サマリー

| 機能          | 実現手段                |
| ----------- | ------------------- |
| SQL変換処理     | `models/*.sql`      |
| Glueカタログ参照  | `sources` 定義        |
| データ質ちテック    | `tests/*.yml`       |
| ドキュメント生成    | `dbt docs generate` |
| DAG/リネージ可視化 | `dbt docs serve`    |
| CI/CD 連携    | GitHub Actions など   |

---
