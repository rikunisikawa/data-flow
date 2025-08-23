# dbt 実装計画 (Issue #73)

## 1. 概要

本計画は、`ai-doc/project-plans/mhealth/` 配下のプランに基づき、dbtを用いたデータ変換、テスト、ドキュメント生成の実装方針を定めるものです。
単純なELTのTransform処理だけでなく、データ品質の担保、再利用性の向上、ドキュメントの自動生成までをスコープとします。

## 2. 参照ドキュメント

- **プロジェクト計画**: `ai-doc/project-plans/mhealth/`
- **既存仕様**:
  - `ai-doc/infra/dbt_environment_overview.md`
  - `ai-doc/infra/system_design.md`

## 3. 実装フェーズ

以下のフェーズに分けて実装を進めます。

### フェーズ1: Staging レイヤーの実装と基礎テスト

このフェーズでは、データソースをdbtに登録し、基本的な前処理を行うStagingモデルを構築します。

1.  **ソースの定義 (`models/src_mhealth.yml`)**
    - S3上のRawデータをdbtのソースとして定義します。
    - `dbt source freshness` を利用して、ソースデータの鮮度を監視する設定を追加します。

2.  **Stagingモデルの作成 (`models/staging/`)**
    - `mhealth` データセットの各テーブルに対応するStagingモデルを作成します。（例: `stg_mhealth__activities.sql`）
    - 責務：データ型のキャスト、カラム名の変更など、最小限の変換に留めます。
    - `ref`関数ではなく`source`関数を使用して、Rawデータを参照します。

3.  **基礎的なデータ品質テストの追加**
    - `models/src_mhealth.yml` に、`not_null`, `unique` などの基本的なテストを追加し、データソースの品質を担保します。

### フェーズ2: Cleansing レイヤーの実装とカスタムテスト

`02_cleansing_plan.md` の内容に基づき、データのクレンジング処理を実装します。

1.  **中間モデル（Intermediate）の作成 (`models/intermediate/`)**
    - クレンジング処理を実装するモデルを作成します。（例: `int_mhealth__cleaned_activities.sql`）
    - 責務：欠損値の補完、外れ値の処理、不要なデータの除外など。

2.  **カスタムテストの導入 (`tests/`)**
    - 業務ロジックに基づいたデータ品質チェックをSQLで記述します。
    - 例：特定のカラムの値が期待される範囲内に収まっているかを確認するテスト (`assert_value_is_within_range.sql`)

### フェーズ3: Feature Engineering レイヤーの実装

`03_feature_engineering_time_domain_plan.md` および `04_feature_engineering_frequency_domain_plan.md` に基づき、特徴量生成を実装します。

1.  **特徴量モデルの作成 (`models/feature/`)**
    - 時間領域特徴量モデル (`fct_mhealth__time_domain_features.sql`) と周波数領域特徴量モデル (`fct_mhealth__frequency_domain_features.sql`) を作成します。
    - `ref`関数を用いて、`int_mhealth__cleaned_activities` モデルを参照します。
    - Window関数や集計関数を多用し、特徴量を生成します。

2.  **特異な値のテスト**
    - 生成された特徴量に無限大や非数（NaN）が含まれていないかを確認するテストを追加します。

### フェーズ4: Data Mart レイヤーとドキュメント生成

`05_final_feature_table_plan.md` に基づき、最終的な分析用テーブルを構築し、プロジェクト全体のドキュメントを整備します。

1.  **最終モデルの作成 (`models/mart/`)**
    - 各特徴量モデルを結合し、機械学習モデルの入力として利用する最終的なテーブルを構築します。（例: `dm_mhealth__final_feature_table.sql`）

2.  **教師データ分割のロジック**
    - モデル内に `CASE WHEN` などを用いて、学習（train）、検証（validation）、テスト（test）のフラグを付与するカラムを追加します。

3.  **ドキュメントの記述 (`models/**/*.yml`)**
    - 全てのモデル、カラムに対して、`description` を記述します。
    - `dbt docs generate` を実行し、データリネージ（依存関係グラフ）を含むプロジェクトドキュメントを生成します。

## 4. 運用・CI/CD

- **dbtの実行**:
  - `dbt build` コマンドを利用し、モデルの実行、テスト、鮮度チェックを一度に実行します。
- **CI/CDへの統合**:
  - 既存のGitHub Actionsワークフローに `dbt build` を組み込み、Pull Request時に自動でテストが実行されるように設定します。
- **スナップショット（将来的な検討）**:
  - 必要に応じて、`snapshot` 機能を用いて、データの変更履歴を追跡する仕組みの導入を検討します。
