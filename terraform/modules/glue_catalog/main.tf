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
    # Enable partition projection to avoid MSCK REPAIR TABLE
    "projection.enabled"               = "true"
    # subject_id: integer range (mHealth subjects are 1..10; keep room if needed)
    "projection.subject_id.type"       = "integer"
    "projection.subject_id.range"      = "1,10"
    # activity_label: enum of 1..12 (exclude 0 = null class)
    "projection.activity_label.type"   = "enum"
    "projection.activity_label.values" = "1,2,3,4,5,6,7,8,9,10,11,12"
    # S3 path template: var.s3_location typically ends with .../stage/
    "storage.location.template"        = "${var.s3_location}subject_id=$${subject_id}/activity_label=$${activity_label}/"
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

  
