# Issue #48: Athenaテーブルの修正 実装計画

## 1. 概要

本Issueは、S3上のパーティション化されたデータが、Athenaテーブル定義に反映されておらず、クエリ結果が0件になる問題を解決することを目的とします。
S3のパーティション構成に合わせてTerraformで管理されているAthena（AWS Glue Catalog）テーブルの定義を修正し、`MSCK REPAIR TABLE` を実行してパーティションをロードすることで、データを正しくクエリできるようにします。

## 2. 関連ファイルの特定

- **Terraform Glue Catalog Module**: `terraform/modules/glue_catalog/main.tf`
  - Athenaテーブル（`aws_glue_catalog_table`）が定義されている可能性が最も高いファイルです。
- **Terraform Root**: `terraform/main.tf`
  - 上記モジュールを呼び出している箇所を確認し、渡されている変数（テーブル名、S3パスなど）を特定します。

## 3. 実装タスク

### 3.1. S3パーティション構造の確認

まず、データが格納されているS3バケットのオブジェクトキー構造を確認し、パーティションキー（例: `year`, `month`, `day` など）とデータ形式（例: `String`）を正確に把握します。

例: `s3://your-bucket/data/year=2025/month=08/day=20/file.parquet`
- パーティションキー: `year`, `month`, `day`
- 型: `string`

### 3.2. Terraformコード (`aws_glue_catalog_table`) の修正

`terraform/modules/glue_catalog/main.tf` に定義されている `aws_glue_catalog_table` リソースに、`partition_keys` ブロックを追加します。

```terraform
resource "aws_glue_catalog_table" "this" {
  # ... 既存のパラメータ ...

  # ↓↓↓ 以下のブロックをS3の構造に合わせて追加 ↓↓↓
  partition_keys {
    name = "year"
    type = "string"
  }

  partition_keys {
    name = "month"
    type = "string"
  }

  partition_keys {
    name = "day"
    type = "string"
  }
  # ↑↑↑ ここまで追加 ↑↑↑
}
```

### 3.3. Terraformの適用

修正したTerraformコードをデプロイします。
1. `terraform plan` を実行し、`aws_glue_catalog_table` リソースの `partition_keys` が追加される差分のみが発生することを確認します。
2. `terraform apply` を実行し、変更をインフラに適用します。

## 4. テストと検証

### 4.1. AWSコンソールでの確認

- AWS Glueのコンソールを開き、対象のテーブルを選択します。
- 「スキーマ」タブで、`partition_keys` で指定したカラムがパーティションキーとして正しく設定されていることを確認します。

### 4.2. Athenaでのパーティションロード

- AWS Athenaのクエリエディタで、以下のコマンドを実行し、S3上のパーティションをテーブルメタデータにロードします。

```sql
MSCK REPAIR TABLE your_database_name.your_table_name;
```

### 4.3. Athenaでのデータクエリ

- パーティションのロードが完了したら、データを取得するクエリを実行して、結果が返ってくることを確認します。

```sql
SELECT * FROM your_database_name.your_table_name LIMIT 10;
```

- 特定のパーティションを指定したクエリも実行し、データが正しく絞り込まれることを確認します。

```sql
SELECT *
FROM your_database_name.your_table_name
WHERE year = '2025' AND month = '08'
LIMIT 10;
```

## 5. 成果物

- `partition_keys` を追加したTerraformコード (`.tf`ファイル) を含むPull Request。
