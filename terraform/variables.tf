variable "base_bucket_name" {
  description = "Base name for the S3 bucket. The workspace name will be prefixed."
  type        = string
}

variable "dbt_image_tag" {
  description = "ECR image tag (per environment) used by the dbt Fargate task."
  type        = string
}

variable "dbt_task_cpu" {
  description = "CPU units for the dbt Fargate task (see Fargate valid combinations)."
  type        = string
  default     = "1024"
}

variable "dbt_task_memory" {
  description = "Memory (MiB) for the dbt Fargate task (see Fargate valid combinations)."
  type        = string
  default     = "2048"
}

variable "athena_workgroup" {
  description = "Athena WorkGroup used by dbt when executing queries."
  type        = string
  default     = "primary"
}

variable "elementary_reports_callback_urls" {
  description = "Cognito callback URLs for the Elementary reports viewer."
  type        = list(string)
  default     = ["https://example.invalid/oauth2/idpresponse"]
}

variable "elementary_reports_logout_urls" {
  description = "Cognito logout URLs for the Elementary reports viewer."
  type        = list(string)
  default     = ["https://example.invalid/logout"]
}
