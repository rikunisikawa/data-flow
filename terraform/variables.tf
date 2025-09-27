variable "base_bucket_name" {
  description = "Base name for the S3 bucket. The workspace name will be prefixed."
  type        = string
}

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "ap-northeast-1"
}

variable "github_repository" {
  description = "The GitHub repository (e.g., 'your-org/your-repo') that can assume the OIDC role."
  type        = string
  default     = "rikunisikawa/data-flow" # Replace with your repository
}