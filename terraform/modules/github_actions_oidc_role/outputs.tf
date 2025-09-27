
output "role_arn" {
  description = "The ARN of the created IAM role for GitHub Actions."
  value       = aws_iam_role.github_actions.arn
}
