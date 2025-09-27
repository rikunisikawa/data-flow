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

## 🏷️ 環境分離（dev/prod）

- 分離戦略: Terraformのworkspace（`dev`/`prod`）でS3バケット名・Glue Database名を分離し、同一コードで環境を切替。
- S3バケット名: `"${terraform.workspace}-${var.base_bucket_name}"`
  - 例: `dev-aws-data-platform-20250607`, `prod-aws-data-platform-20250607`
- Glue Data Catalog（ステージ領域）
  - Database名: `"${terraform.workspace}_stage_mhealth"`（例: `dev_stage_mhealth` / `prod_stage_mhealth`）
  - Table: `raw_activities`（Locationは各環境の `s3://<bucket>/stage/`）
- dbt（加工出力）
  - Catalog: `awsdatacatalog`
  - Schema（Glue Database相当）: 環境変数で指定（推奨）
    - dev: `DBT_SCHEMA=dev_processed`
    - prod: `DBT_SCHEMA=prod_processed`
  - 出力先S3: `S3_DATA_DIR=s3://<bucket>/processed/`（環境ごとにバケットが異なる）

補足:
- 現状の `.env.dev` は `DBT_SCHEMA=processed` を既定としているが、運用上の衝突回避のため `dev_processed` / `prod_processed` の採用を推奨。
- CIではPRごとに `DBT_SCHEMA=processed_ci_<run_id>` のように一意化すると衝突を避けやすい。

---

## 📚 データ階層（raw / stage / processed）

- raw: 取得直後の生ログ（`.log`）。Lambda `download_and_upload` が `s3://<bucket>/raw/` に配置。
- stage: Parquet化＋パーティション（`subject_id` × `activity_label`）。Lambda `convert_log_to_parquet` が `s3://<bucket>/stage/` に配置。
  - Glue Catalog: `<workspace>_stage_mhealth.raw_activities`
  - Athenaの参照元としてdbtの`source`が利用。
- processed: dbtによる変換・集約の成果物をParquetで格納（テーブルごとにサブディレクトリ）。
  - Glue Catalog: `DBT_SCHEMA`（例: `dev_processed` / `prod_processed`）配下に `cleaned_activities`, `featured_activities` などを作成。
  - 出力先: `s3://<bucket>/processed/<table>/`

クエリ最適化:
- Athenaでは `stage` のパーティションキーを積極活用（`subject_id`, `activity_label` でフィルタ）。
- `processed` は列指向かつ集約済みのため、分析クエリコストを削減。

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

---

## 🤖 モデル成果物管理

機械学習モデルの再現性と追跡可能性を確保するため、モデル成果物（学習済みモデル、メトリクス、パラメータ等）はS3上で一元的にバージョン管理されます。

### S3パス命名規則

モデル成果物は、以下の命名規則に従ってS3バケットに保存されます。

```
s3://<bucket-name>/models/<YYYYMMDD-HHMMSS>/<model-name>-<version>/
├── model.pkl
├── params.json
└── metrics.json
```

- **`<bucket-name>`**: 環境に応じたS3バケット名 (`dev-aws-data-platform-20250607` など)。
- **`models/`**: モデル成果物を格納する固定プレフィックス。
- **`<YYYYMMDD-HHMMSS>`**: 学習実行日時（UTC）。これにより、いつ実行された学習の成果物かを一意に識別できます。
- **`<model-name>-<version>`**: モデル名とセマンティックバージョン（例: `mhealth-classifier-v1.2.0`）。
- **`model.pkl`**: 学習済みのモデルオブジェクト（シリアライズ形式はモデルに依存）。
- **`params.json`**: 学習時に使用したハイパーパラメータ。
- **`metrics.json`**: モデルの評価指標（精度、再現率など）。

### バージョニング

- モデルのバージョンは、コードやdbtモデルとは独立して、セマンティックバージョニング (`MAJOR.MINOR.PATCH`) で管理します。
- 新しいモデルバージョンをリリースする際は、Gitのタグ (`models/mhealth-classifier/v1.2.0` のようにプレフィックスを付けることを推奨) を作成し、それをトリガーに本番環境へのデプロイパイプラインが実行されるフローを想定します。

### メトリクスJSONスキーマ (`metrics.json`)

モデルの評価指標を記録する `metrics.json` は、以下のスキーマに従います。

```json
{
  "model_name": "mhealth-classifier",
  "model_version": "1.2.0",
  "execution_timestamp": "2025-09-27T10:00:00Z",
  "evaluation_dataset": "s3://<bucket-name>/processed/featured_activities/run_id=xyz/",
  "metrics": {
    "accuracy": 0.95,
    "precision": 0.96,
    "recall": 0.95,
    "f1_score": 0.95,
    "confusion_matrix": [
      [100, 2],
      [5, 110]
    ]
  },
  "git_commit_hash": "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0"
}
```

- **`model_name`**: モデルの一意な名前。
- **`model_version`**: モデルのセマンティックバージョン。
- **`execution_timestamp`**: 評価が実行された日時 (ISO 8601形式)。
- **`evaluation_dataset`**: 評価に使用したデータセットのS3パス。
- **`metrics`**: 評価指標のキーと値のペア。
- **`git_commit_hash`**: このモデルを生成したコードのGitコミットハッシュ。コードの再現性を担保します。
