# 🧠 dbt 導入手順書（Athena + Glue 対応）

## 🌟 目的

KaggleHub経由で取得した mHealth データセットをETLし、 Glue Data Catalog経由でAthenaから分析可能にしたデータに対して dbtを用いて以下を実現する:

- SQLによる変換 (Transform)
- テストによるデータ品質保証
- ドキュメントとデータリネージの可視化

---

## 1️⃣ 必要ツールのインストール

Python仮想環境を作成し、以下をインストール：

```bash
pip install dbt-athena-community
```

---

## 2️⃣ プロジェクト初期化

```bash
dbt init data_flow_dbt
cd data_flow_dbt
```

選択肢：

- adapter: athena
- プロファイル名: data\_flow
- デフォルト構成でOK

---

## 3️⃣ profiles.yml の作成（\~/.dbt/profiles.yml）

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

> Athenaのクエリ一時保存場所として、`s3_staging_dir`は存在する必要あり

---

## 4️⃣ ソーステーブルの定義

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

## 5️⃣ モデルの作成

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

## 6️⃣ テストの作成

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

## 7️⃣ 実行コマンド

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

## 8️⃣ Glue Catalog の事前準備

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

## 9️⃣ CI/CD との連携

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

