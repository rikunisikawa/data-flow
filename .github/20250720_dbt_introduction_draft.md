# dbt 導入 Draft 作成

## 概要

本タスクでは、データ変換、テスト、ドキュメント化を目的として、既存のデータパイプラインにdbtを導入するための初期設定を行いました。

## 実装内容

### 1. dbt プロジェクトの初期化

`dbt init` コマンドの代わりに、手動でdbtプロジェクトのディレクトリ構造と設定ファイルを作成しました。

- `data_flow_dbt/` ディレクトリを作成
- `models`, `tests` などのサブディレクトリを作成
- `dbt_project.yml`: プロジェクトの基本設定ファイルを作成
- `.gitignore`: dbtが生成する一時ファイル (`target/`, `logs/`など)をGitの追跡対象から除外

### 2. dbt モデルとソースの定義

Issueの要件に基づき、以下のファイルを作成しました。

- `models/src_mhealth.yml`: Glue Data Catalogにある `raw_activity` テーブルをdbtのソースとして定義しました。
- `models/cleaned_activities.sql`: `raw_activity` テーブルから `accel_x` がNULLでないレコードを抽出する、基本的な変換モデルを作成しました。
- `models/tests.yml`: `cleaned_activities` モデルの `id` と `timestamp` カラムに対して `not_null` テストを定義し、データの品質を保証するための設定を行いました。

### 3. 依存関係の追加

dbtをAthenaと連携させるために必要な `dbt-athena-community` ライブラリを `layer/build/requirements.txt` に追加しました。これにより、Lambdaレイヤーにdbtの実行環境が含まれるようになります。

## 理由

- **dbtの採用**: SQL中心でデータ変換ロジックを管理し、テストやドキュメント化を容易にすることで、データパイプラインの保守性と信頼性を向上させるため。
- **手動でのプロジェクト作成**: `dbt init` は対話形式のコマンドであり、自動化された環境での実行が困難なため、必要なファイルとディレクトリを直接作成する方法を選択しました。
- **依存関係の集約**: `requirements.txt` にライブラリを追加することで、SAM/Lambdaのデプロイ時にdbtの実行環境が自動的に構築されるようにするためです。
