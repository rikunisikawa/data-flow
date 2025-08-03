resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  handler          = var.handler
  runtime          = var.runtime
  architectures    = var.architectures
  memory_size      = var.memory_size
  timeout          = var.timeout
  filename         = var.filename
  source_code_hash = filebase64sha256(var.filename)
  role             = var.role_arn
  layers           = var.layers

  environment {
    variables = var.environment_variables
  }
}
