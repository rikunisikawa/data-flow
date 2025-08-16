# dbt 環境概要

このドキュメントは、現在のプロジェクトにおけるdbt環境の構成と役割について説明します。

## 1. 概要

このdbtプロジェクト (`data_flow_dbt`) は、AWS上のデータレイクにある生データをETL処理し、分析用のデータマートを構築することを目的としています。データウェアハウスエンジンとしてAWS Athenaを使用しており、インフラの定義はTerraformで、一連の処理はStep Functionsでオーケストレーションされることを想定しています。

## 2. プロジェクト構成

dbtプロジェクトは `data_flow_dbt/` ディレクトリに格納されています。主要なファイルとディレクトリの役割は以下の通りです。

-   `dbt_project.yml`: dbtプロジェクト全体の設定ファイル。
-   `dbt_profiles/profiles.yml`: データベース（Athena）への接続情報。
-   `models/`: データ変換のロジックを定義するSQLファイル。
-   `ddl/`: dbtの管理外で実行されるテーブル作成用のSQLファイル。
-   `tests/`: データ品質を検証するためのテスト。

## 3. 接続設定 (`dbt_profiles/profiles.yml`)

dbtは `dbt_profiles/profiles.yml` の設定に基づきAthenaに接続します。

```yaml
data_flow_dbt:
  target: dev
  outputs:
    dev:
      type: athena
      s3_staging_dir: "{{ var('S3_STAGING_DIR') }}"
      s3_data_dir: "{{ var('S3_DATA_DIR') }}"
      region_name: "{{ var('AWS_REGION') }}"
      database: "{{ var('GLUE_DATABASE') }}"
      schema: "mhealth"
      
      threads: 4
      work_group: "{{ var('ATHENA_WORK_GROUP') }}"
```

-   **接続タイプ**: `athena`
-   **変数化**: S3のパスやデータベース名などの具体的な値は、`dbt run` 実行時に `--vars` オプションで渡される変数 (`var(...)`) によって動的に設定されます。これにより、環境ごとの差異を吸収しています。

## 4. データパイプライン

### 4.1. ソースデータ

データソースは `models/src_mhealth.yml` で定義されています。

```yaml
version: 2

sources:
  - name: mhealth_stage
    database: awsdatacatalog
    schema: stage_mhealth
    tables:
      - name: raw_activities
```

-   Glueデータカタログの `stage_mhealth` データベースにある `raw_activities` テーブルを `mhealth_stage` という名前のソースとして参照します。

### 4.2. 変換モデル (`cleaned_activities.sql`)

`models/cleaned_activities.sql` が中核となる変換モデルです。

```sql
{{ config(materialized='table') }}

WITH source AS (

    SELECT
        *,
        -- Extract user_id from the S3 file path
        regexp_extract("$path", 'mHealth_subject(\d+)', 1) AS user_id
    FROM
        {{ source('mhealth_stage', 'raw_activities') }}

),

renamed AS (

    SELECT
        user_id,
        activity_label,
        (chest_acc_x + chest_acc_y + chest_acc_z) / 3 AS chest_acc_avg,
        (left_ankle_acc_x + left_ankle_acc_y + left_ankle_acc_z) / 3 AS left_ankle_acc_avg,
        (right_lower_arm_acc_x + right_lower_arm_acc_y + right_lower_arm_acc_z) / 3 AS right_lower_arm_acc_avg
    FROM
        source
    WHERE
        activity_label != 0

)

SELECT * FROM renamed
```

このモデルは以下の処理を実行します。

1.  **ソースの読み込み**: `raw_activities` テーブルからデータを読み込みます。
2.  **user_idの抽出**: S3のファイルパスから正規表現で `user_id` を抽出します。
3.  **データのフィルタリング**: `activity_label` が `0` のレコード（活動なし）を除外します。
4.  **特徴量生成**: 各センサーの3軸加速度データから平均値を計算します。
5.  **テーブル作成**: 処理後のデータを `cleaned_activities` テーブルとしてマテリアライズ（実体化）します。

## 5. テスト

`models/tests.yml` でデータに対するテストが定義されています。

```yaml
version: 2

models:
  - name: cleaned_activities
    columns:
      - name: user_id
        tests:
          - not_null
      - name: activity_label
        tests:
          - not_null
```

-   `cleaned_activities` テーブルの `user_id` と `activity_label` カラムに `not_null` 制約テストが設定されており、データの整合性を担保しています。

## 6. 実行方法

dbtモデルの実行は、通常以下のコマンドで行います。

```bash
dbt run --vars '{ "S3_STAGING_DIR": "s3://...", "S3_DATA_DIR": "s3://...", ... }'
```

テストは以下のコマンドで実行します。

```bash
dbt test
```
