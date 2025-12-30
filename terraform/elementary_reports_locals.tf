locals {
  elementary_reports_prefix                = "processed/elementary-reports"
  elementary_reports_origin_id             = "elementary-reports-s3-origin"
  elementary_reports_cognito_domain_prefix = replace("${terraform.workspace}-elementary-reports", "_", "-")
  elementary_reports_redirect_uri          = var.elementary_reports_callback_urls[0]
  elementary_reports_logout_uri            = var.elementary_reports_logout_urls[0]
}
