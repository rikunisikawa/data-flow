resource "local_file" "elementary_edge_auth_source" {
  filename = "${path.module}/edge_auth_build/index.js"
  content = templatefile("${path.module}/edge_auth/index.js.tmpl", {
    cognito_domain        = "https://${aws_cognito_user_pool_domain.elementary_reports.domain}.auth.${data.aws_region.current.name}.amazoncognito.com"
    cognito_client_id     = aws_cognito_user_pool_client.elementary_reports.id
    cognito_client_secret = aws_cognito_user_pool_client.elementary_reports.client_secret
    cognito_redirect_uri  = local.elementary_reports_redirect_uri
    cognito_scope         = "openid email profile"
    cookie_name           = "id_token"
    callback_path         = "/oauth2/idpresponse"
  })
}

data "archive_file" "elementary_edge_auth" {
  type        = "zip"
  source_dir  = "${path.module}/edge_auth_build"
  output_path = "${path.module}/edge_auth.zip"
  depends_on  = [local_file.elementary_edge_auth_source]
}

resource "aws_iam_role" "elementary_edge_auth" {
  name = "${terraform.workspace}-elementary-edge-auth"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "edgelambda.amazonaws.com"
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "elementary_edge_auth_basic" {
  role       = aws_iam_role.elementary_edge_auth.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "elementary_edge_auth" {
  provider         = aws.us_east_1
  function_name    = "${terraform.workspace}-elementary-edge-auth"
  role             = aws_iam_role.elementary_edge_auth.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  filename         = data.archive_file.elementary_edge_auth.output_path
  source_code_hash = data.archive_file.elementary_edge_auth.output_base64sha256
  publish          = true

  depends_on = [aws_iam_role_policy_attachment.elementary_edge_auth_basic]
}
