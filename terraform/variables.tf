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

variable "local_terraform_deploy_principal_arn" {
  description = "ARN of the IAM user/role allowed to assume the local Terraform deploy role."
  type        = string
  default     = ""
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

variable "fitbit_client_id" {
  description = "Fitbit OAuth client ID."
  type        = string
  sensitive   = true
}

variable "fitbit_client_secret" {
  description = "Fitbit OAuth client secret."
  type        = string
  sensitive   = true
}

variable "fitbit_webhook_secret" {
  description = "Fitbit webhook verification secret."
  type        = string
  sensitive   = true
}

variable "fitbit_poll_schedule" {
  description = "EventBridge Scheduler expression for Fitbit poller."
  type        = string
  default     = "rate(5 minutes)"
}

variable "fitbit_poll_lookback_minutes" {
  description = "Lookback window in minutes for Fitbit intraday polling."
  type        = string
  default     = "10"
}

variable "fitbit_min_poll_interval_seconds" {
  description = "Minimum poll interval per user in seconds."
  type        = string
  default     = "300"
}

variable "fitbit_poller_shard_id" {
  description = "Shard ID for poller lambda."
  type        = string
  default     = "0"
}

variable "fitbit_poller_shard_count" {
  description = "Total shard count for poller lambda."
  type        = string
  default     = "1"
}
