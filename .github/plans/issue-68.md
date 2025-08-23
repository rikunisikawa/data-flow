# dbt 実装計画 (Issue #68)

## 1. 概要

本計画は、`ai-doc/project-plans/mhealth/` 配下のプランに基づき、dbt を用いたデータ変換処理を実装するための具体的な手順を定義する。
単純なデータ変換（Transform）だけでなく、データ品質の担保、ドキュメント生成、機械学習向けの特徴量生成までをスコープとし、dbt の機能を活用した堅牢なデータ基盤の構築を目指す。

## 2. 前提条件

- `mhealth` の生データが、所定のS3バケット（rawゾーン）に配置済みであること。
- AWS Glue データカタログに生データ用のテーブル定義が完了していること。
- dbt の実行環境（プロファイル設定含む）が `dbt_profiles/profiles.yml` に基づいて構成済みであること。

## 3. 実装方針

dbt のベストプラクティスに従い、`sources` -> `staging` -> `intermediate` -> `marts` の階層的なモデル構造で実装を進める。

### Phase 1: Source（データソース）の定義と Staging モデルの構築

- **目的**: 生データをdbtプロジェクトの入力として定義し、基本的な前処理（データ型変換、カラム名変更など）を施した Staging レイヤーを構築する。
- **作業内容**:
  1.  `models/src_mhealth.yml` にて、Glue データカタログのテーブルを `source` として定義する。
  2.  `source` から1対1に対応する Staging モデル（例: `stg_activities.sql`）を作成する。
      - `ref` 関数の代わりに `source` 関数を使用して生データを参照する。
      - カラム名のスネークケースへの統一、データ型のキャストなど、最小限の変換のみを行う。

### Phase 2: Intermediate モデル（中間モデル）の実装

- **目的**: `ai-doc/project-plans/mhealth/02_cleansing_plan.md` および `03_feature_engineering_..._plan.md` に基づき、データクレンジングと特徴量生成を行う。
- **作業内容**:
  1.  複数の Staging モデルを `ref` 関数で結合し、クレンジング処理を実装する。（例: `cleaned_activities.sql`）
  2.  時間領域・周波数領域の特徴量など、機械学習モデルの入力となる特徴量を計算する中間モデルを実装する。
      - `GROUP BY` やウィンドウ関数を多用することが想定される。
      - 複雑なロジックは、可読性向上のため複数のモデルに分割する（例: `int_time_domain_features.sql`）。

### Phase 3: Marts モデル（分析用データマート）の構築

- **目的**: `ai-doc/project-plans/mhealth/05_final_feature_table_plan.md` に基づき、最終的な分析用テーブルや機械学習モデルの学習用データセットを作成する。
- **作業内容**:
  1.  中間モデルを `ref` で参照し、最終的な粒度に集約したモデルを作成する。（例: `fct_activity_features.sql`）
  2.  モデルの用途（分析、MLなど）に応じて、カラムの選択や最終的な整形を行う。

### Phase 4: データ品質テストの実装

- **目的**: 各モデルのデータ品質を保証するためのテストを実装する。
- **作業内容**:
  1.  **Generic Test**: `not_null`, `unique`, `accepted_values`, `relationships` などの組込みテストを `.yml` ファイルに記述する。
      - 例: 主キーの一意性・非NULL制約、ステータス値が特定の値（例: 'active', 'inactive'）のみであることを保証。
  2.  **Singular Test**: 業務ロジックに特化したカスタムテストを `tests/` ディレクトリにSQLファイルとして作成する。
      - 例: センサーデータの値が物理的にありえない範囲（例: 加速度が100Gを超える）になっていないか検証。

### Phase 5: ドキュメントの生成と整備

- **目的**: プロジェクトの可読性とメンテナンス性を向上させるため、dbt のドキュメント機能を活用する。
- **作業内容**:
  1.  各モデル、カラムの役割やビジネス的な意味を `.yml` ファイルの `description` として記述する。
  2.  `dbt docs generate` コマンドでドキュメントを生成し、`dbt docs serve` で内容を確認する。
  3.  自動生成された Lineage（データリネージ）を確認し、モデル間の依存関係が意図通りであることを検証する。

## 4. タスク一覧

- [ ] **Phase 1: Staging**
  - [ ] `models/src_mhealth.yml`: 生データテーブルを `source` として定義
  - [ ] `models/staging/stg_mhealth_raw.sql`: 生データを参照するStagingモデルを作成
- [ ] **Phase 2: Intermediate**
  - [ ] `models/intermediate/int_cleansed_activities.sql`: データクレンジング処理を実装
  - [ ] `models/intermediate/int_time_domain_features.sql`: 時間領域の特徴量を生成
  - [ ] `models/intermediate/int_freq_domain_features.sql`: 周波数領域の特徴量を生成
- [ ] **Phase 3: Marts**
  - [ ] `models/marts/fct_activity_features.sql`: 最終的な特徴量テーブルを構築
- [ ] **Phase 4: Testing**
  - [ ] `models/staging/staging.yml`: Stagingモデルの主キーに `unique`, `not_null` テストを追加
  - [ ] `models/marts/marts.yml`: Martsモデルの主要なカラムにテストを追加
  - [ ] `tests/assert_sensor_values_are_reasonable.sql`: センサーデータの異常値チェックテストを作成
- [ ] **Phase 5: Documentation**
  - [ ] すべての `.yml` ファイルにモデルとカラムの `description` を記述
  - [ ] `dbt docs generate` を実行し、成果物を確認

## 5. 成果物

- dbt モデルファイル (`.sql`)
- dbt スキーマ定義ファイル (`.yml`)
- dbt カスタムテストファイル (`.sql`)
- （生成物）dbt ドキュメントサイト

## 6. その他

- 実装はブランチを切り、Pull Request ベースでレビューを行う。
- 各モデルの実装が完了するたびに `dbt run` と `dbt test` を実行し、動作確認を行う。
