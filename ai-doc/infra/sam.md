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

| ステップ | 処理内容                           | 実装先        |
|----------|------------------------------------|----------------|
| ①        | Kaggle APIからlogファイル取得→S3保存 | Lambda①       |
| ②        | log → Parquet形式に変換             | Lambda②またはGlue① |
| ③        | データ整形（カラム名統一など）       | Glue②         |
| ④        | Glue Catalog登録 & Athena対応     | Glue②         |

---

## 📦 SAM定義リソース（template.yaml）

- Lambda①：`download_and_upload.lambda_handler`
- Lambda②：`convert_log_to_parquet.lambda_handler`
- Step Functions：上記LambdaとGlueジョブを連携
- 環境変数：`BUCKET_NAME=aws-data-platform-20250607`

---

## ✅ Lambda①（logダウンロード → S3保存）

- **入力**：なし（定時実行）
- **処理**：
  - `kaggle` 公式APIでmHealth logファイルをダウンロード
  - S3 `/raw/` にアップロード
- **依存ライブラリ**：`kaggle`
- **認証**：`kaggle.json` をSecrets ManagerやParameter Storeに保存し、Lambda起動時に取得
- **共通ライブラリ**：`boto3`

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

- **入力**：S3 `/raw/*.log`
- **処理**：
  - `pandas` でログを DataFrame として読み込み（区切り文字に応じて処理）
  - Parquet形式に変換 → `/stage/` に保存
- **依存ライブラリ**：`pandas`, `pyarrow`, `boto3`

---

## ✅ Glue②（整形・変換・カタログ）

- **入力**：S3 `/stage/*.parquet`
- **処理**：
  - タイムスタンプ型変換
  - カラム名の正規化（例：空白・大文字 → snake_case）
- **出力**：S3 `/processed/`
- **カタログ**：Glue Data Catalog に `mhealth` テーブル作成

---

## ✅ Athena DDL（想定スキーマ）

```sql
CREATE EXTERNAL TABLE mhealth (
  user_id string,
  activity string,
  timestamp timestamp,
  sensor1 double,
  sensor2 double,
  sensor3 double
)
STORED AS PARQUET
LOCATION 's3://aws-data-platform-20250607/processed/';
```

※logファイルの具体的な形式に応じてスキーマは変更

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
