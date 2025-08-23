# Issue #66: 過去論文指示書の分割と実装計画

## 1. 目的

MHEALTHデータセットを用いた過去の研究（人間活動認識の分類タスク）を、既存のデータ基盤上で再現する。具体的には、データのEDAから特徴量作成、モデル構築、評価までの一連のパイプラインを、dbtとPythonを組み合わせて実装する。

本計画は、大規模な指示を現実的な開発タスクに分割し、段階的に実行することを目的とする。各タスクの成果物は `ai-doc/project-plans/mhealth/` ディレクトリにMarkdownファイルとして蓄積していく。

## 2. 全体方針

- **データソース**: 新規にデータはダウンロードせず、既にデータレイク（S3）に存在するであろうMHEALTHデータセットを唯一のソースとする。
- **技術スタック**:
    - **データ変換・集計**: dbt を最大限に活用し、SQLで実行可能な前処理、EDA、特徴量作成を行う。
    - **高度な処理・機械学習**: SQLでの実装が困難な処理（周波数領域の特徴量作成など）や、機械学習モデルの開発・評価は Python で行う。
- **ワークフロー**: dbtで処理した結果をデータウェアハウス（Athena/Redshiftなど）に出力し、それをPythonが読み込んで機械学習パイプラインを実行する流れを想定する。

## 3. 実装計画（タスク分割）

### フェーズ1: データ探索的分析 (EDA) と前処理

#### タスク1-1: 既存データの仕様確認と基本集計 (dbt)
- **内容**:
    - dbtの`sources.yml`に定義されているであろう生データの仕様（スキーマ、データ型、nullの有無）を改めて確認する。
    - 各被験者 (subject)、各活動 (activity) ごとのデータ件数、センサーごとのレコード数を集計するdbtモデルを作成する。
    - センサーデータの基本的な統計量（平均、中央値、標準偏差、最大値、最小値）を計算するdbtモデルを作成する。
- **成果物**:
    - `ai-doc/project-plans/mhealth/01_eda_plan.md`
    - dbtモデル: `models/mhealth/staging/stg_mhealth_raw.sql`
    - dbtモデル: `models/mhealth/intermediate/int_mhealth_basic_stats.sql`

#### タスク1-2: データクレンジングと整形 (dbt)
- **内容**:
    - 欠損値の補間や異常値の除去など、基本的なクレンジング処理を行うdbtモデルを作成する。
    - 後の特徴量計算がしやすいように、データを整形し、ベースとなるテーブルを作成する。
- **成果物**:
    - `ai-doc/project-plans/mhealth/02_cleansing_plan.md`
    - dbtモデル: `models/mhealth/intermediate/int_mhealth_cleaned.sql`

### フェーズ2: 特徴量エンジニアリング

#### タスク2-1: 時間領域特徴量の作成 (dbt)
- **内容**:
    - 論文で一般的に使用される時間領域の特徴量を計算する。
    - 具体的には、一定時間幅のウィンドウ（例: 2.56秒）を設定し、その中の各センサーデータに対して以下の特徴量を計算するdbtモデルを作成する。
        - 平均値, 標準偏差, 分散, 最大値, 最小値, 中央絶対偏差 (MAD), RMS (二乗平均平方根) など。
- **成果物**:
    - `ai-doc/project-plans/mhealth/03_feature_engineering_time_domain_plan.md`
    - dbtモデル: `models/mhealth/features/fct_mhealth_time_domain_features.sql`

#### タスク2-2: 周波数領域特徴量の作成 (Python)
- **内容**:
    - SQLでの実装が困難な周波数領域の特徴量を計算するPythonスクリプトを作成する。
    - dbtで作成した `int_mhealth_cleaned` テーブルを読み込み、FFT（高速フーリエ変換）を適用して、エネルギースペクトルやスペクトルエントロピーなどの特徴量を計算する。
    - 計算結果は、後続のdbtで読み込めるようにS3上のParquet形式で出力する。
- **成果物**:
    - `ai-doc/project-plans/mhealth/04_feature_engineering_frequency_domain_plan.md`
    - Pythonスクリプト: `scripts/mhealth/build_frequency_features.py`
    - 出力データ: `s3://<bucket>/mhealth/features/frequency_domain_features/`

### フェーズ3: 機械学習モデルの実装

#### タスク3-1: 最終的な特徴量テーブルの作成 (dbt)
- **内容**:
    - タスク2-1と2-2で作成した時間領域・周波数領域の特徴量を結合し、機械学習モデルの入力となる最終的な特徴量テーブルを作成するdbtモデルを実装する。
    - Pythonで作成した特徴量データをdbtの`source`として新たに追加する。
- **成果物**:
    - `ai-doc/project-plans/mhealth/05_final_feature_table_plan.md`
    - dbtモデル: `models/mhealth/features/fct_mhealth_final_features.sql`
    - dbtソース定義: `models/mhealth/src_mhealth_features.yml`

#### タスク3-2: 教師データの分割とモデル学習 (Python)
- **内容**:
    - `fct_mhealth_final_features` テーブルを読み込み、教師データとテストデータに分割するPythonスクリプトを作成する。（例: 被験者IDで分割）
    - O'Halloranら (2019) の研究を参考に、まずはベースラインとしてXGBoostとMLP（多層パーセプトロン）モデルを学習させる。
    - 学習済みモデルはシリアライズして保存する（例: pickle, joblib）。
- **成果物**:
    - `ai-doc/project-plans/mhealth/06_model_training_plan.md`
    - Pythonスクリプト: `scripts/mhealth/train_model.py`
    - 保存されたモデルファイル

#### タスク3-3: モデル評価 (Python)
- **内容**:
    - テストデータを用いてモデルの性能を評価するPythonスクリプトを作成する。
    - 評価指標としてAccuracy、F1スコア、混同行列などを計算し、結果をログやレポートファイルに出力する。
- **成果物**:
    - `ai-doc/project-plans/mhealth/07_model_evaluation_plan.md`
    - Pythonスクリプト: `scripts/mhealth/evaluate_model.py`
    - 評価レポート (例: `reports/mhealth/evaluation_report.txt`)

## 4. ディレクトリ構造の提案

本計画で作成するドキュメントやスクリプトは、以下のディレクトリ構造で管理する。

```
.
├── ai-doc/
│   └── project-plans/
│       └── mhealth/
│           ├── 01_eda_plan.md
│           ├── 02_cleansing_plan.md
│           ├── 03_feature_engineering_time_domain_plan.md
│           ├── 04_feature_engineering_frequency_domain_plan.md
│           ├── 05_final_feature_table_plan.md
│           ├── 06_model_training_plan.md
│           └── 07_model_evaluation_plan.md
├── data_flow_dbt/
│   └── models/
│       └── mhealth/
│           ├── staging/
│           │   └── stg_mhealth_raw.sql
│           ├── intermediate/
│           │   ├── int_mhealth_basic_stats.sql
│           │   └── int_mhealth_cleaned.sql
│           ├── features/
│           │   ├── fct_mhealth_time_domain_features.sql
│           │   └── fct_mhealth_final_features.sql
│           └── src_mhealth_features.yml
└── scripts/
    └── mhealth/
        ├── build_frequency_features.py
        ├── train_model.py
        └── evaluate_model.py
```
