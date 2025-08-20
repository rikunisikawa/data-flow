# terraform/modules/glue_catalog/variables.tf

variable "database_name" {
  description = "The name of the Glue Catalog database."
  type        = string
}

variable "table_name" {
  description = "The name of the Glue Catalog table."
  type        = string
}

variable "s3_location" {
  description = "The S3 location of the data."
  type        = string
}

variable "columns" {
  description = "A list of column definitions for the table."
  type = list(object({
    name = string
    type = string
  }))
}
