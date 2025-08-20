# terraform/modules/glue_catalog/outputs.tf

output "database_name" {
  description = "The name of the created Glue database."
  value       = aws_glue_catalog_database.this.name
}

output "table_name" {
  description = "The name of the created Glue table."
  value       = aws_glue_catalog_table.this.name
}
