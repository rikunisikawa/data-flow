# 2025-07-29: dbt導入によるデータ変換基盤の構築

## 概要

本タスクでは、データ変換・品質管理の強化を目的として、プロジェクトにdbt (Data Build Tool) を導入した。
これまでGlueで個別に行っていたデータ整形・カタログ登録処理をdbtに置き換えることで、データ変換ロジックをSQLで宣言的に管理し、テストとドキュメント化を容易にするアーキテクチャを構築した。

## 主な変更点

1.  **dbtプロジェクトの初期化**
    - `dbt-athena-community` アダプタを使用してdbtプロジェクト (`data_flow_dbt`) をセットアップした。
    - Athenaへの接続情報は `dbt_profiles/profiles.yml` で管理し、環境変数を介して注入する構成とした。

2.  **アーキテクチャの変更**
    - `ai-doc/infra/system_design.md` を更新し、データ処理フローをdbt中心に変更した。
    - LambdaがS3の `/stage/` に出力したParquetファイルを、dbtがAthena経由で直接参照・変換する流れを定義した。

3.  **Athena外部テーブルの定義**
    - dbtがソースとして参照するS3上の生データ (`/stage/` ディレクトリ) をAthenaでテーブルとして認識させるため、DDLファイル (`ddl/create_stage_raw_activities.sql`) を作成した。
    - これにより、dbtは `source('mhealth_stage', 'raw_activities')` としてデータを読み込めるようになった。

4.  **dbtモデルとテストの実装**
    - **モデル (`models/cleaned_activities.sql`)**: 
        - S3のファイルパスから `user_id` を抽出する処理を追加した。
        - `activity_label` が `0` の不要なデータを除外した。
        - センサーデータを集約し、新しい特徴量カラムを作成した。
    - **テスト (`models/tests.yml`)**: 
        - `user_id` と `activity_label` がNULLでないことを保証するテストを追加し、データの信頼性を向上させた。

## 実行結果

- `dbt run` により、変換モデルが正常に実行され、`processed` スキーマに `cleaned_activities` テーブルが作成されることを確認した。
- `dbt test` により、定義したデータ品質テストにすべて合格することを確認した。

## 実行した主なコマンド

```bash
# dbt関連ライブラリのインストール
pip install dbt-athena-community

# dbtプロジェクトの初期化
dbt init data_flow_dbt

# dbtの設定とAthenaへの接続確認
dbt debug --profiles-dir ../dbt_profiles --vars '{"S3_STAGING_DIR": "s3://aws-data-platform-20250607/dbt-temp/", "S3_DATA_DIR": "s3://aws-data-platform-20250607/processed/", "AWS_REGION": "ap-northeast-1", "GLUE_DATABASE": "awsdatacatalog", "GLUE_RAW_SCHEMA": "default", "ATHENA_WORK_GROUP": "primary"}'

# dbtモデルの実行
dbt run --profiles-dir ../dbt_profiles --vars '{"S3_STAGING_DIR": "s3://aws-data-platform-20250607/dbt-temp/", "S3_DATA_DIR": "s3://aws-data-platform-20250607/processed/", "AWS_REGION": "ap-northeast-1", "GLUE_DATABASE": "awsdatacatalog", "GLUE_RAW_SCHEMA": "default", "ATHENA_WORK_GROUP": "primary"}'

# dbtテストの実行
dbt test --profiles-dir ../dbt_profiles --vars '{"S3_STAGING_DIR": "s3://aws-data-platform-20250607/dbt-temp/", "S3_DATA_DIR": "s3://aws-data-platform-20250607/processed/", "AWS_REGION": "ap-northeast-1", "GLUE_DATABASE": "awsdatacatalog", "GLUE_RAW_SCHEMA": "default", "ATHENA_WORK_GROUP": "primary"}'

# 不要なサンプルファイルの削除
rm -rf data_flow_dbt/models/example
```

## 今後の展望

- 今回構築したdbt基盤を拡張し、より複雑なデータ変換や分析モデルを追加していく。
- dbtのドキュメント生成機能 (`dbt docs generate`) を活用し、データリネージを可視化する。
- CI/CDパイプラインに `dbt run` と `dbt test` を組み込み、データ変換プロセスの自動化と品質保証を強化する。
