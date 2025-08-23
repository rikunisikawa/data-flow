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
├── raw/        # Lambda が保存（logファイル）
├── stage/      # Lambda or Glue が保存（Parquet）
└── processed/  # dbt が保存（整形後Parquet）
```

---

## 🔄 データ処理フロー（ETL）

| ステップ | 処理内容 | 実装先 |
|---|---|---|
| ① | Kaggle APIからlogファイル取得→S3 `/raw/` に保存 | Lambda |
| ② | log → Parquet形式に変換し、S3 `/stage/` に保存 | Lambda |
| ③ | **dbtによるデータ変換**: S3 `/stage/` のデータをソースとし、`cleaned_activities` モデルを実行。`user_id`の抽出、各センサー加速度の平均値算出、不要データ（`activity_label=0`）の除外を行う。 | dbt (`dbt run`) |
| ④ | **dbtによるデータ格納**: 変換後のデータをS3 `/processed/` にParquet形式でテーブルとして保存する。 | dbt (`dbt run`) |
| ⑤ | **dbtによるデータ品質テスト**: `tests.yml` に基づき、データの整合性や品質をテストする。 | dbt (`dbt test`) |

---

## 📦 SAM定義リソース（template.yaml）

- **Lambda Functions**：
  - `download_and_upload.lambda_handler`
  - `convert_log_to_parquet.lambda_handler`
- **Step Functions**：2つのLambda関数を順次実行制御
- **環境変数**：`BUCKET_NAME=aws-data-platform-20250607`
- **EventBridge**：Step Functionsの定時実行トリガー

---

## ✅ Lambda（logダウンロード → S3保存）

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

## ✅ Lambda（log → Parquet変換）

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

**dbtとの連携：**
Lambdaによって `subject_id` をパーティションキーとしてS3パスに埋め込む一方、dbtモデル側ではそのファイルパスから `regexp_extract` を用いて `user_id` を抽出し、テーブル内の列として追加します。
これにより、Athenaでのクエリ時にパーティションによるデータスキャン量の削減と、テーブル内での `user_id` を使った集計・分析が両立されます。

**利点：**
- 被験者ごとにデータを簡単にフィルタできる → クロス被験者検証に便利
- ラベルごとにデータ分布を効率確認可能
- Glue Data Catalog登録時、`subject_id` と `activity_label` をパーティション列として設定可能

---

## ✅ dbtモデル詳細

dbtプロジェクトは、S3 `/stage/` に保存されたParquetデータをAthena経由で読み込み、変換処理とデータ品質テストを実行します。最終的な成果物はS3 `/processed/` にテーブルとして保存されます。

### dbtプロジェクト設定 (`dbt_project.yml`)

- **デフォルトスキーマ**: `processed`
  - `dbt run` で作成されるモデル（テーブル）は、特別な指定がない限り `processed` スキーマに出力されます。
- **デフォルトマテリアライゼーション**: `table`
  - モデルはAthena上でビューではなく、実体のあるテーブルとして作成されます。これにより、クエリパフォーマンスが向上します。

### ソース定義 (`src_mhealth.yml`)

- **データベース**: `awsdatacatalog`
  - dbtはAWS Glueデータカタログをデータベースとして認識します。
- **スキーマ**: `stage_mhealth`
- **テーブル**: `raw_activities`
  - このソーステーブルは、実質的にS3 `/stage/` ディレクトリにあるParquetデータを指し示すAthenaの外部テーブルです。

### モデル仕様 (`cleaned_activities.sql`)

`cleaned_activities` モデルは、ソースデータを変換し、分析に適した形式に整形する主要なロジックを担います。

- **`user_id`の抽出**:
  - S3のファイルパス（Athenaでは `$path` 列としてアクセス可能）から、`regexp_extract` 関数を用いて正規表現で `user_id` を抽出します。
  - 例: `s3://.../mHealth_subject1_...` → `1`
- **センサーデータの平均化**:
  - 3つのセンサー（胸、左足首、右下腕）の3軸加速度（X, Y, Z）をそれぞれ平均し、`chest_acc_avg` のような新しい列を作成します。これにより、各センサーの全体的な活動量を単一の指標で評価しやすくなります。
- **nullクラスの除外**:
  - `activity_label` が `0` のデータは、どの活動にも分類されない「nullクラス」であるため、`WHERE`句で除外します。これにより、分析対象を意味のある活動データのみに絞り込みます。

---

## ✅ Athena DDL

dbtから参照する「生データ」のテーブルと、dbtによって生成される「変換後データ」のテーブル定義です。

### ソーステーブル (`stage_mhealth.raw_activities`)

このDDLは、dbtプロジェクトの外部で一度だけ実行し、S3 `/stage/` のデータを指すテーブルを作成する必要があります。

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
PARTITIONED BY (subject_id int)
STORED AS PARQUET
LOCATION 's3://aws-data-platform-20250607/stage/';
```

### dbt成果物テーブル (`processed.cleaned_activities`) - 参考

`dbt run` を実行すると、`processed` スキーマに以下の構造を持つテーブルが作成されます。これはdbtによって自動的に管理されるため、手動でDDLを実行する必要はありません。

```sql
CREATE EXTERNAL TABLE `processed.cleaned_activities`(
  `user_id` string, 
  `activity_label` bigint,
  `chest_acc_avg` double, 
  `left_ankle_acc_avg` double, 
  `right_lower_arm_acc_avg` double
)
STORED AS PARQUET
LOCATION 's3://aws-data-platform-20250607/processed/cleaned_activities/'
```

---

## 🧪 テスト条件

- Lambda関数は `sam local invoke` でローカルテストする
- dbtの変換処理は、サンプルデータを用いてテストし、AthenaでSELECT結果を確認する
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
