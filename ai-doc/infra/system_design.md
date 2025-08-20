# ✅ AI向け指示用仕様書：SAMを用いたデータ基盤開発

## 🎯 開発目的

- Kaggle公式API経由で取得した**mHealthデータセット（logファイル）**をETL処理し、**Parquet形式でS3に格納**。
- それをAthenaで分析できるようにする自動化データ基盤を、**AWS SAM（Serverless Application Model）**で構築する。

---

## 🔧 技術スタック・前提

- **ランタイム**：Python 3.11
- **ツール**：AWS SAM, Docker, AWS CLI, kaggle公式API
- **AWSサービス**：
  - Lambda（Python）
  - Step Functions（ETLフロー制御）
  - Glue（整形＆カタログ更新）
  - EventBridge（定時実行）
  - S3（データ保存）
  - Athena（分析）
  - Glue Data Catalog（メタデータ管理）

---

## 📁 S3構成と用途

```
s3://aws-data-platform-20250607/
├── raw/        # Lambda① が保存（logファイル）
├── stage/      # Lambda② or Glue① が保存（Parquet）
└── processed/  # Glue② が保存（整形後Parquet）
```

---

## 🔄 データ処理フロー（ETL）

| ステップ | 処理内容                                 | 実装先                |
|----------|------------------------------------------|-----------------------|
| ①        | Kaggle APIからlogファイル取得→S3保存     | Lambda①              |
| ②        | log → Parquet形式に変換                  | Lambda②              |
| ③        | dbtによるデータ変換・整形                | dbt (Athena経由)     |
| ④        | dbtによるデータ品質テスト                | dbt (Athena経由)     |

---

## 📦 SAM定義リソース（template.yaml）

- **Lambda①**：`download_and_upload.lambda_handler`
- **Lambda②**：`convert_log_to_parquet.lambda_handler`
- **Step Functions**：Lambda①→Lambda②の順次実行を制御
- **環境変数**：`BUCKET_NAME=aws-data-platform-20250607`
- **EventBridge**：Step Functionsの定時実行トリガー

---

## ✅ Lambda①（logダウンロード → S3保存）

- **入力**：なし（定時実行）
- **処理**：
  - kaggle公式APIでmHealth logファイルをダウンロード
  - S3 `/raw/` にアップロード
- **依存ライブラリ**：kaggle
- **認証**：`kaggle.json` をSecrets ManagerやParameter Storeに保存し、Lambda起動時に取得
- **共通ライブラリ**：boto3

**処理例コード**

```python
import boto3
import os
import zipfile
from kaggle.api.kaggle_api_extended import KaggleApi

def lambda_handler(event, context):
  api = KaggleApi()
  api.authenticate()

  dataset = 'nirmalsankalana/mhealth-dataset-data-set'
  download_path = '/tmp/mhealth.zip'
  extract_path = '/tmp/mhealth'

  api.dataset_download_files(dataset, path='/tmp', unzip=False)

  with zipfile.ZipFile(download_path, 'r') as zip_ref:
    zip_ref.extractall(extract_path)

  s3 = boto3.client('s3')
  bucket = os.environ['BUCKET_NAME']

  for root, dirs, files in os.walk(extract_path):
    for file in files:
      if file.endswith(".log"):
        file_path = os.path.join(root, file)
        s3_key = f'raw/{file}'
        s3.upload_file(file_path, bucket, s3_key)
```

---

## ✅ Lambda②（log → Parquet変換）

- **入力**：Step Functions経由での実行（S3イベントトリガーではない）
- **処理**：
  - S3 `/raw/` フォルダ内の全ての`.log`ファイルをスキャン
  - pandasでログをDataFrameとして読み込み（区切り文字に応じて処理）
  - Parquet形式に変換 → `/stage/` に保存
  - このとき、`subject_id` と `activity_label` をパーティションキーとして付与
- **依存ライブラリ**：pandas, pyarrow, boto3
- **トリガー**：Step Functions State Machine

---

## ✅ パーティション戦略

- **目的**：被験者単位の外挿評価（LOSOCV）やラベルごとの集計分析を効率化。Athenaでのクエリスキャン量を削減し、ETL後の分析を最適化。
- **パーティションキー**：
  - `subject_id`（ファイル名 mHealth_subjectX.log から抽出）
  - `activity_label`（logファイル最終列の値）

**ディレクトリ構造例：**

```
s3://aws-data-platform-20250607/stage/
  subject_id=1/activity_label=4/part-000.parquet
  subject_id=1/activity_label=10/part-001.parquet
  subject_id=2/activity_label=5/part-000.parquet
  ...
```

**利点：**
- 被験者ごとにデータを簡単にフィルタできる → クロス被験者検証に便利
- ラベルごとにデータ分布を効率確認可能
- Glue Data Catalog登録時、`subject_id` と `activity_label` をパーティション列として設定可能

---

## ✅ dbtによる変換・テスト

- **入力**：S3 `/stage/*.parquet` （Athenaの外部テーブル経由）
- **処理**：
  - `dbt run` を実行し、/stage/の生データを変換・整形
  - `dbt test` を実行し、データの品質をテスト
- **出力**：S3 `/processed/` （dbtがAthena経由でテーブル作成）
- **カタログ**：dbtがAthena/Glue Data Catalogにモデルに対応するテーブル・ビューを作成

---

## ✅ Athena DDL（dbtのソース定義用）

dbtから参照する「生データ」のテーブルを定義します。このDDLは、dbtプロジェクトの外部で一度だけ実行する必要があります。

```sql
CREATE DATABASE IF NOT EXISTS stage_mhealth;

CREATE EXTERNAL TABLE stage_mhealth.raw_activities (
  chest_acc_x double,
  chest_acc_y double,
  chest_acc_z double,
  chest_ecg_1 double,
  chest_ecg_2 double,
  left_ankle_acc_x double,
  left_ankle_acc_y double,
  left_ankle_acc_z double,
  left_ankle_gyro_x double,
  left_ankle_gyro_y double,
  left_ankle_gyro_z double,
  left_ankle_mag_x double,
  left_ankle_mag_y double,
  left_ankle_mag_z double,
  right_lower_arm_acc_x double,
  right_lower_arm_acc_y double,
  right_lower_arm_acc_z double,
  right_lower_arm_gyro_x double,
  right_lower_arm_gyro_y double,
  right_lower_arm_gyro_z double,
  right_lower_arm_mag_x double,
  right_lower_arm_mag_y double,
  right_lower_arm_mag_z double,
  activity_label bigint
)
PARTITIONED BY (subject_id int, activity_label int)
STORED AS PARQUET
LOCATION 's3://aws-data-platform-20250607/stage/';
```

---

## 🧪 テスト条件

- Lambda関数は `sam local invoke` でローカルテストする
- Glue②は最初にサンプルデータでテストしてAthenaでSELECT確認
- 全体のStep Functionsは `sam deploy` 後、EventBridgeトリガーで動作確認

---

## ✅ ローカルで依存ライブラリインストール

```bash
pip install -r convert_log_to_parquet/requirements.txt --target convert_log_to_parquet
```

---

## 📚 mHealthデータセット概要

### 出典

- Oresti Banos, Rafael Garcia, Alejandro Saez（University of Granada）
- 連絡先: oresti '@' ugr.es / oresti.bl '@' gmail.com

### データセット情報

- 10名の被験者が12種類の身体活動を実施
- 胸・右手首・左足首にセンサー装着
- 加速度・ジャイロ・磁気・ECG（胸のみ）を50Hzで記録
- 各被験者ごとに`mHealth_subject.log`ファイルで保存

#### 活動一覧

| ラベル | 活動内容                       | 時間/回数      |
|--------|-------------------------------|----------------|
| L1     | Standing still                | 1分            |
| L2     | Sitting and relaxing          | 1分            |
| L3     | Lying down                    | 1分            |
| L4     | Walking                       | 1分            |
| L5     | Climbing stairs               | 1分            |
| L6     | Waist bends forward           | 20回           |
| L7     | Frontal elevation of arms     | 20回           |
| L8     | Knees bending (crouching)     | 20回           |
| L9     | Cycling                       | 1分            |
| L10    | Jogging                       | 1分            |
| L11    | Running                       | 1分            |
| L12    | Jump front & back             | 20回           |

#### カラム情報

| カラム | 内容                                      |
|--------|-------------------------------------------|
| 1-3    | 胸センサー加速度（X, Y, Z）               |
| 4-5    | 胸センサーECG（リード1, 2）               |
| 6-8    | 左足首加速度（X, Y, Z）                   |
| 9-11   | 左足首ジャイロ（X, Y, Z）                 |
| 12-14  | 左足首磁気センサー（X, Y, Z）             |
| 15-17  | 右下腕加速度（X, Y, Z）                   |
| 18-20  | 右下腕ジャイロ（X, Y, Z）                 |
| 21-23  | 右下腕磁気センサー（X, Y, Z）             |
| 24     | ラベル（0はnullクラス）                   |

- 単位：加速度（m/s²）、ジャイロ（deg/s）、磁場（local）、ECG（mV）

#### 論文・引用

- Banos, O. et al., mHealthDroid: a novel framework for agile development of mobile health applications. IWAAL 2014.
- Banos, O. et al., Design, implementation and validation of a novel open framework for agile development of mobile health applications. BioMedical Engineering OnLine, 2015.

> このデータセットを利用する場合は上記論文を引用してください。  
> 利用報告は oresti.bl '@' gmail.com まで。
