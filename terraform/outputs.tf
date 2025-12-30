output "elementary_reports_url" {
  value = "https://${aws_cloudfront_distribution.elementary_reports.domain_name}"
}

output "elementary_reports_cognito_domain" {
  value = "https://${aws_cognito_user_pool_domain.elementary_reports.domain}.auth.${data.aws_region.current.name}.amazoncognito.com"
}
