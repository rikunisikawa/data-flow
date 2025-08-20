# Issue-44 実装計画: Athenaテーブル作成Terraformコード追加

## 1. 目的

`ai-doc/infra/system_design.md` のテーブル定義に基づき、Athenaから参照できるGlueのデータベースおよびテーブルをTerraformで作成する。

## 2. 方針

Issueで提示された管理パターンのうち、再現性とIaCの原則に最も合致する **「パターン1: Glueカタログを直接定義」** を採用する。
また、パーティション管理を自動化するため、**Partition Projection** を活用する。

作成対象のテーブルは、dbtのソースとなる `raw_activities` とする。

## 3. 計画概要

Terraformで以下のAWSリソースを定義する。

1.  `aws_glue_catalog_database`: `stage_mhealth` データベース
2.  `aws_glue_catalog_table`: `raw_activities` テーブル

これらのリソースは、再利用性を考慮し、新しいTerraformモジュール (`terraform/modules/glue_catalog`) として作成する。

## 4. タスク詳細

### 4.1. Terraformモジュールの作成

Athena/Glue関連のリソースを管理するため、`terraform/modules/glue_catalog` ディレクトリを新規に作成する。

- **`terraform/modules/glue_catalog/main.tf`**:
  - `aws_glue_catalog_database` と `aws_glue_catalog_table` リソースを定義する。
- **`terraform/modules/glue_catalog/variables.tf`**:
  - データベース名、テーブル名、S3ロケーション、カラム定義などを変数として定義する。
- **`terraform/modules/glue_catalog/outputs.tf`**:
  - 作成したデータベース名やテーブル名をアウトプットとして定義する。

### 4.2. `aws_glue_catalog_database` の定義

`system_design.md` に基づき、`stage_mhealth` という名前のデータベースを作成する。

```hcl
# terraform/modules/glue_catalog/main.tf

resource "aws_glue_catalog_database" "this" {
  name = var.database_name
}
```

### 4.3. `aws_glue_catalog_table` の定義

`raw_activities` テーブルを定義する。カラム定義は `system_design.md` のDDLを反映させる。

- **パーティション**:
  - 元のDDLにパーティションはないが、運用を考慮して日付ベースのPartition Projection (`date`) を追加する。
  - これにより、`s3://<bucket_name>/stage/date=YYYY/MM/DD/` のようなパス構造のデータを自動でパーティションとして認識できるようになる。
  - Lambda(`convert_log_to_parquet`)のS3出力パスも、この構造に合わせる改修が別途必要になる可能性がある点を留意する。

- **コードスニペット**:

```hcl
# terraform/modules/glue_catalog/main.tf

resource "aws_glue_catalog_table" "this" {
  database_name = aws_glue_catalog_database.this.name
  name          = var.table_name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    classification              = "parquet"
    EXTERNAL                    = "TRUE"
    "projection.enabled"        = "true"
    "projection.date.type"      = "date"
    "projection.date.range"     = "2024/01/01,NOW"
    "projection.date.format"    = "yyyy/MM/dd"
    "storage.location.template" = "${var.s3_location}date=$${date}/"
  }

  storage_descriptor {
    location      = var.s3_location
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "parquet-serde"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
      parameters = {
        "serialization.format" = "1"
      }
    }

    dynamic "columns" {
      for_each = var.columns
      content {
        name = columns.value.name
        type = columns.value.type
      }
    }
  }

  partition_keys {
    name = "date"
    type = "string"
  }
}
```

### 4.4. ルートモジュールでの呼び出し

作成した `glue_catalog` モジュールを `terraform/main.tf` から呼び出す。

```hcl
# terraform/main.tf

module "glue_catalog_raw_activities" {
  source = "./modules/glue_catalog"

  database_name = "stage_mhealth"
  table_name    = "raw_activities"
  s3_location   = "s3://${aws_s3_bucket.data_bucket.id}/stage/" # 既存のS3バケットリソースを参照

  columns = [
    { name = "chest_acc_x", type = "double" },
    { name = "chest_acc_y", type = "double" },
    { name = "chest_acc_z", type = "double" },
    { name = "chest_ecg_1", type = "double" },
    { name = "chest_ecg_2", type = "double" },
    { name = "left_ankle_acc_x", type = "double" },
    { name = "left_ankle_acc_y", type = "double" },
    { name = "left_ankle_acc_z", type = "double" },
    { name = "left_ankle_gyro_x", type = "double" },
    { name = "left_ankle_gyro_y", type = "double" },
    { name = "left_ankle_gyro_z", type = "double" },
    { name = "left_ankle_mag_x", type = "double" },
    { name = "left_ankle_mag_y", type = "double" },
    { name = "left_ankle_mag_z", type = "double" },
    { name = "right_lower_arm_acc_x", type = "double" },
    { name = "right_lower_arm_acc_y", type = "double" },
    { name = "right_lower_arm_acc_z", type = "double" },
    { name = "right_lower_arm_gyro_x", type = "double" },
    { name = "right_lower_arm_gyro_y", type = "double" },
    { name = "right_lower_arm_gyro_z", type = "double" },
    { name = "right_lower_arm_mag_x", type = "double" },
    { name = "right_lower_arm_mag_y", type = "double" },
    { name = "right_lower_arm_mag_z", type = "double" },
    { name = "activity_label", type = "bigint" }
  ]
}
```

## 5. 成果物

- `terraform/modules/glue_catalog/main.tf`
- `terraform/modules/glue_catalog/variables.tf`
- `terraform/modules/glue_catalog/outputs.tf`
- `terraform/main.tf` (モジュール呼び出し部分の追記)

## 6. 確認方法

1.  `terraform init` を実行し、新しいモジュールを初期化する。
2.  `terraform plan` を実行し、`aws_glue_catalog_database` と `aws_glue_catalog_table` が意図通りに作成されることを確認する。
3.  `terraform apply` を実行し、リソースをデプロイする。
4.  AWSコンソールのGlueおよびAthenaで、データベースとテーブルが正しく作成されていることを確認する。
