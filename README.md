# data-flow
データ基盤全般を構築

# ✅ データ基盤構築フロー設計仕様書

## 🎯 目的

KaggleHub経由で取得したmHealthデータセットをETL処理し、Athenaで分析可能な形式（Parquet＋適切なスキーマ）でS3に格納する自動化データ基盤を構築する。

---

## 🗺️ 全体構成図（処理フロー）

**EventBridge Scheduler**  
→ 定時実行（例：毎日8:00）  
→ **Step Functions**をトリガー

**Step Functions ステップ**
1. Lambda① → データ取得・S3保存  
2. Lambda② または Glue① → CSV → Parquet変換  
3. Glue② → データ整形 → S3（分析用パス）に保存

**Athena**  
→ Glue Data CatalogによりS3上のデータにクエリ可能

---

## 📦 使用サービスと役割

| サービス       | 役割                                       |
|----------------|--------------------------------------------|
| EventBridge    | 定時トリガー                               |
| Step Functions | 処理フロー制御                             |
| Lambda①        | KaggleHubでデータ取得し、S3保存            |
| Lambda② / Glue①| CSV → Parquet変換                          |
| Glue②          | データ変換・整形・カタログ更新             |
| Athena         | クエリ・分析実行                           |

---

## 🧱 S3 構成例

```
s3://your-bucket-name/
├── raw/             ← Lambda①保存 (CSV)
├── stage/           ← Lambda②またはGlue① (Parquet)
└── processed/       ← Glue②出力 (整形済Parquet)
```

---

## 💻 ローカル開発 & デプロイ手順

### ✅ ステップ0：前提ツールのインストール

- Python 3.11+
- Docker
- AWS CLI & `aws configure`
- AWS SAM CLI (`brew install aws/tap/aws-sam-cli`)
- `kagglehub` インストール：`pip install kagglehub`

---

### ✅ ステップ1：SAM プロジェクト作成

```bash
sam init
# → runtime: python3.11
# → template: Hello World Example
```

---

### ✅ ステップ2：Lambda① 作成（データ取得＆S3保存）

```python
# lambda/download_and_upload.py
import json
import boto3
import kagglehub
from pathlib import Path
import os

s3 = boto3.client('s3')
BUCKET = os.environ['BUCKET_NAME']

def lambda_handler(event, context):
    path = kagglehub.dataset_download("nirmalsankalana/mhealth-dataset-data-set")
    local_path = Path(path)
    for file in local_path.glob("**/*.csv"):
        s3.upload_file(str(file), BUCKET, f"raw/{file.name}")
    return {"status": "uploaded", "files": len(list(local_path.glob('*.csv')))}
```

---

### ✅ ステップ3：Lambda②（CSV → Parquet） or Glue① を作成

**Lambda版：`pandas + pyarrow` を使う**

```bash
pip install pandas pyarrow -t lambda/convert/
```

```python
# lambda/convert_csv_to_parquet.py
import boto3
import pandas as pd
import pyarrow.parquet as pq
import pyarrow as pa
import os
from io import BytesIO

s3 = boto3.client("s3")
BUCKET = os.environ['BUCKET_NAME']

def lambda_handler(event, context):
    response = s3.list_objects_v2(Bucket=BUCKET, Prefix='raw/')
    for obj in response.get('Contents', []):
        key = obj['Key']
        if key.endswith('.csv'):
            csv_obj = s3.get_object(Bucket=BUCKET, Key=key)
            df = pd.read_csv(csv_obj['Body'])
            table = pa.Table.from_pandas(df)
            parquet_buffer = BytesIO()
            pq.write_table(table, parquet_buffer)
            s3.put_object(Bucket=BUCKET, Key=key.replace("raw/", "stage/").replace(".csv", ".parquet"),
                          Body=parquet_buffer.getvalue())
```

---

### ✅ ステップ4：Glue② 作成（整形・カタログ化）

- データの型変換（例：timestamp変換、カラム名正規化）
- `processed/` へParquet形式で保存
- Glue Data Catalog にテーブル作成

---

### ✅ ステップ5：Step Functions 定義（template.yaml）

```yaml
Resources:
  Workflow:
    Type: AWS::StepFunctions::StateMachine
    Properties:
      DefinitionString:
        Fn::Sub: |
          {
            "StartAt": "DownloadCSV",
            "States": {
              "DownloadCSV": {
                "Type": "Task",
                "Resource": "${DownloadFunction.Arn}",
                "Next": "ConvertParquet"
              },
              "ConvertParquet": {
                "Type": "Task",
                "Resource": "${ConvertFunction.Arn}",
                "Next": "GlueTransform"
              },
              "GlueTransform": {
                "Type": "Task",
                "Resource": "arn:aws:states:::glue:startJobRun.sync",
                "Parameters": {
                  "JobName": "YourGlueJobName"
                },
                "End": true
              }
            }
          }

  DownloadFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: lambda/
      Handler: download_and_upload.lambda_handler
      Runtime: python3.11
      Environment:
        Variables:
          BUCKET_NAME: your-bucket-name
```

---

### ✅ ステップ6：ローカルテスト

```bash
sam build
sam local invoke DownloadFunction
```

---

### ✅ ステップ7：デプロイ

```bash
sam deploy --guided
```

---

### ✅ ステップ8：Athena設定

Glue Data CatalogにParquetテーブルを作成。以下のDDLを実行：

```sql
CREATE EXTERNAL TABLE mhealth (
  id string,
  timestamp timestamp,
  accel_x double,
  accel_y double,
  accel_z double
)
STORED AS PARQUET
LOCATION 's3://your-bucket-name/processed/';
```

---

## 📌 補足

- GlueのSpark処理に切り替えることで、大量データへの対応が容易になります。
- LambdaでParquet変換する場合はメモリ制限に注意（512MB〜1GB推奨）。
