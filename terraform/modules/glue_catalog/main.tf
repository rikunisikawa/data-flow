# terraform/modules/glue_catalog/main.tf

resource "aws_glue_catalog_database" "this" {
  name = var.database_name
}

resource "aws_glue_catalog_table" "this" {
  database_name = aws_glue_catalog_database.this.name
  name          = var.table_name
  table_type    = "EXTERNAL_TABLE"

  partition_keys {
    name = "subject_id"
    type = "string"
  }

  partition_keys {
    name = "activity_label"
    type = "string"
  }

  parameters = {
    classification = "parquet"
    EXTERNAL       = "TRUE"
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
}

  
