# 仕様: MHEALTHデータセットを用いた過去研究のトレース

## 1. 背景 (Background)

MHEALTH（Mobile Health）データセットは、ウェアラブルセンサを用いて人間の活動を記録したデータであり、人間活動認識（HAR）の研究で広く利用されている。過去には、機械学習モデル（XGBoost, MLPなど）や深層学習モデル（CNN, LSTMなど）を用いて高い分類精度が達成されている。

本プロジェクトのデータ分析基盤の実用性を検証するため、このMHEALTHデータセットを用いた過去の研究分析フロー（データ準備、特徴量作成、モデル学習、評価）を、既存のAWSおよびdbt環境上で再現する。

## 2. 目的 (Goals)

- 既存のAWS（S3, Glue, Athena, Lambda, Step Functions）およびdbt基盤上で、MHEALTHデータセットを用いた機械学習パイプラインを構築する。
- O'Halloran & Curry (2019) の研究で高い性能を示した**XGBoostモデル**をターゲットとし、データの前処理からモデル評価までの一連の流れを実装する。
- dbtによるデータ変換・特徴量エンジニアリングと、Pythonによるモデル開発の連携を実現する。

## 3. 非目的 (Non-Goals)

- すべての過去研究を網羅的に再現すること。
- 論文の精度を超える、世界最高性能のモデルを開発すること。
- 新規のインフラストラクチャを構築すること（既存の基盤を最大限活用する）。
- リアルタイム推論APIを構築すること（今回はバッチ処理による学習・評価パイプラインに集中する）。

## 4. アーキテクチャ・設計 (Architecture & Design)

### 4.1. データフロー

1.  **データソース**: S3に格納済みの `stage_raw_activities` テーブル（Glueデータカタログ経由）。
2.  **データ変換 (dbt)**:
    - `cleaned_activities`: 生データの基本的なクレンジング（データ型変換、カラム名変更など）。
    - `featured_activities`: センサーデータから統計的特徴量（平均、標準偏差、最大、最小など）を計算し、モデル学習用のテーブルを作成する。
3.  **モデル学習・評価 (Python & AWS)**:
    - **Step Functions** がパイプライン全体をオーケストレーションする。
    - **Lambda関数**がPythonスクリプトを実行する。
    - スクリプトは **AWS Data Wrangler** を用いてAthenaから `featured_activities` テーブルを読み込む。
    - データを学習データとテストデータに分割する。
    - **XGBoostモデル**を学習し、テストデータで性能を評価する（Accuracy, F1-Scoreなど）。
    - 評価結果（メトリクス）と学習済みモデルをS3に保存する。

### 4.2. 主要コンポーネント

- **dbt**:
    - `models/cleaned_activities.sql` （既存または微修正）
    - `models/featured_activities.sql` （新規作成）
- **Pythonスクリプト**:
    - `model_training/train_evaluate.py` （新規作成）
- **AWS**:
    - `state_machine/data_processing.asl.json` （更新）
    - `terraform/modules/lambda/main.tf` （モデル学習用Lambdaの定義を追加）
    - `layer/src/requirements.txt` （モデル学習に必要なライブラリを追加）
