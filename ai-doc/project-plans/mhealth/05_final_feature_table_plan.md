# MHEALTH Final Feature Table Plan: 最終的な特徴量テーブルの作成

## 1. 目的

dbt を使用して、時間領域と周波数領域でそれぞれ計算された特徴量を統合し、機械学習モデルの学習に直接使用できる単一のワイドテーブルを作成する。

## 2. 背景

機械学習モデルの学習プロセスを効率化するためには、必要なすべての特徴量が整理された単一のテーブル（またはビュー）を用意することが望ましい。このステップでは、これまでdbtとPythonで別々に作成してきた特徴量データをマージし、モデル開発のインプットとなるデータセットを完成させる。

## 3. タスク詳細

### 3.1. 周波数領域特徴量の dbt source 化

- **作業内容**:
    1.  前のタスクでPythonスクリプトが出力したS3上のParquetファイル群を、dbtの新しい `source` として定義する。
    2.  `data_flow_dbt/models/mhealth/src_mhealth_features.yml` （または適切な既存のymlファイル）に、S3パス、フォーマット、スキーマ情報を記述する。
    3.  `dbt source freshness` を実行し、dbtがS3上の特徴量データを正しく認識できることを確認する。

- **成果物**:
    - 更新された `data_flow_dbt/models/mhealth/src_mhealth_features.yml`

### 3.2. Staging モデルの作成

- **作業内容**:
    1.  新しく定義した `source` （周波数領域特徴量）からデータを読み込み、カラム名の変更やデータ型のキャストなど、基本的な整形を行う Staging モデルを作成する。
- **成果物**:
    - dbt モデル: `data_flow_dbt/models/mhealth/staging/stg_mhealth_frequency_features.sql`

### 3.3. 特徴量テーブルの結合

- **作業内容**:
    1.  時間領域特徴量モデル (`fct_mhealth_time_domain_features`) と、周波数領域特徴量のStagingモデル (`stg_mhealth_frequency_features`) を結合 (join) する。
    2.  結合キーには `window_id` や `subject_id` など、両方のテーブルで一意にウィンドウを特定できるカラムを使用する。
    3.  結合する際には、各ウィンドウに対応する正解ラベル（`activity_id`）も付与する。
    4.  最終的なモデルは、1行が1ウィンドウ（1サンプル）を表し、カラムがすべての特徴量とターゲット変数（活動ID）で構成されるワイドな形式になるように設計する。

- **成果物**:
    - dbt モデル: `data_flow_dbt/models/mhealth/features/fct_mhealth_final_features.sql`

## 4. 完了条件

- `dbt run` が `fct_mhealth_final_features` モデルまで正常に完了する。
- `fct_mhealth_final_features` のレコード数が、元のウィンドウ数と一致していることを確認する。
- 結合されたテーブルに欠損値が発生していないか確認し、発生している場合は原因を調査して修正する。
- 最終的な特徴量テーブルのスキーマが、機械学習モデルの入力として適切な形式になっている。
