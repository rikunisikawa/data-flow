# MHEALTH EDA Plan: 既存データの仕様確認と基本集計

## 1. 目的

dbt を使用して、既存の MHEALTH データセットの基本的な特性を理解し、分析の土台を築く。具体的には、データの構造を確認し、被験者や活動ごとのデータ分布を明らかにする。

## 2. 背景

本格的な特徴量作成やモデル構築に進む前に、データがどのような形式で、どのような内容を含んでいるかを正確に把握することが不可欠である。このEDA（探索的データ分析）プロセスにより、後のタスクで発生しうる問題を未然に防ぎ、分析の方向性を定める。

## 3. タスク詳細

### 3.1. dbt source の定義とテスト

- **作業内容**:
    1.  データレイク（S3）上の MHEALTH データセットを指す dbt `source` を `data_flow_dbt/models/mhealth/src_mhealth.yml` に定義する。（すでに存在する場合は内容を確認・更新する）
    2.  `dbt source freshness` を実行し、データが期待通りに読み込めることを確認する。
    3.  `source` に対して、少なくとも `not_null` と `unique` のテストを主要なカラム（例: `subject_id`, タイムスタンプ）に追加し、`dbt test` を実行してデータの品質を担保する。

- **成果物**:
    - 更新された `data_flow_dbt/models/mhealth/src_mhealth.yml`

### 3.2. Staging モデルの作成

- **作業内容**:
    1.  `source` からデータを読み込み、カラム名の変更（スネークケースへの統一など）、データ型のキャスト、不要カラムの除外など、基本的な整形を行う Staging モデルを作成する。
- **成果物**:
    - dbt モデル: `data_flow_dbt/models/mhealth/staging/stg_mhealth_raw.sql`

### 3.3. 基本的な集計モデルの作成

- **作業内容**:
    1.  `stg_mhealth_raw` を参照し、以下の内容を集計する Intermediate モデルを作成する。
        - 被験者ごと (`subject_id`) の総レコード数
        - 活動ごと (`activity_id`) の総レコード数
        - 被験者と活動の組み合わせごとのレコード数
    2.  各センサーデータの基本的な統計量（`avg`, `stddev`, `min`, `max`）を計算するモデルを作成する。
- **成果物**:
    - dbt モデル: `data_flow_dbt/models/mhealth/intermediate/int_mhealth_record_counts.sql`
    - dbt モデル: `data_flow_dbt/models/mhealth/intermediate/int_mhealth_basic_stats.sql`

## 4. 完了条件

- `dbt run` がすべてのモデルで成功する。
- `dbt test` がすべてのテストで成功する。
- 作成された dbt モデルが、データの基本的な特性（レコード数、統計量）を正しく反映している。
