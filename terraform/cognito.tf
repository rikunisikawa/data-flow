resource "aws_cognito_user_pool" "elementary_reports" {
  name = "${terraform.workspace}-elementary-reports"
}

resource "aws_cognito_user_pool_domain" "elementary_reports" {
  domain       = local.elementary_reports_cognito_domain_prefix
  user_pool_id = aws_cognito_user_pool.elementary_reports.id
}

resource "aws_cognito_user_pool_client" "elementary_reports" {
  name                                 = "${terraform.workspace}-elementary-reports"
  user_pool_id                         = aws_cognito_user_pool.elementary_reports.id
  generate_secret                      = true
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  callback_urls                        = var.elementary_reports_callback_urls
  logout_urls                          = var.elementary_reports_logout_urls
  supported_identity_providers         = ["COGNITO"]
}
