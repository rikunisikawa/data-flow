
variable "github_repository" {
  description = "The GitHub repository (e.g., 'your-org/your-repo') that can assume this role."
  type        = string
}

variable "role_name_prefix" {
  description = "A prefix for the IAM role name to ensure uniqueness."
  type        = string
  default     = "data-flow"
}

variable "policy_arns" {
  description = "A list of IAM policy ARNs to attach to the GitHub Actions role."
  type        = list(string)
  default     = [
    "arn:aws:iam::aws:policy/AdministratorAccess" # Note: It is recommended to use more restrictive policies.
  ]
}
