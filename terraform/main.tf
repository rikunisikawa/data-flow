data "aws_ssm_parameter" "kaggle_username" {
  name = "/data-flow/kaggle/username"
  with_decryption = true
}

data "aws_ssm_parameter" "kaggle_key" {
  name = "/data-flow/kaggle/key"
  with_decryption = true
}

module "download_and_upload_lambda" {
  source = "./modules/lambda"

  function_name         = "download_and_upload_function"
  handler               = "download_and_upload.lambda_handler"
  runtime               = "python3.11"
  architectures         = ["x86_64"]
  memory_size           = 1024
  timeout               = 300
  filename              = "/app/build/download_and_upload.zip"
  role_arn              = aws_iam_role.lambda_execution_role.arn
  layers                = [aws_lambda_layer_version.kaggle_api_layer.arn]
  environment_variables = {
    BUCKET_NAME     = var.bucket_name
    KAGGLE_USERNAME = data.aws_ssm_parameter.kaggle_username.value
    KAGGLE_KEY      = data.aws_ssm_parameter.kaggle_key.value
  }
}

module "convert_log_to_parquet_lambda" {
  source = "./modules/lambda"

  function_name         = "convert_log_to_parquet_function"
  handler               = "convert_log_to_parquet.lambda_handler"
  runtime               = "python3.11"
  architectures         = ["x86_64"]
  memory_size           = 1024
  timeout               = 300
  filename              = "/app/build/convert_log_to_parquet.zip"
  role_arn              = aws_iam_role.lambda_execution_role.arn
  layers                = [aws_lambda_layer_version.kaggle_api_layer.arn]
  environment_variables = {
    BUCKET_NAME = var.bucket_name
  }
}

module "glue_job_role" {
  source = "./modules/iam"

  role_name          = "mhealth-glue-job-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
        Action    = "sts:AssumeRole"
      },
    ]
  })
  policies = [
    {
      name    = "GlueS3Access"
      document = jsonencode({
        Version   = "2012-10-17"
        Statement = [
          {
            Effect   = "Allow"
            Action   = [
              "s3:GetObject",
              "s3:PutObject",
            ]
            Resource = "arn:aws:s3:::${var.bucket_name}/*"
          },
        ]
      })
    },
  ]
}

# Lambda実行ロール (仮)
resource "aws_iam_role" "lambda_execution_role" {
  name               = "lambda-execution-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action    = "sts:AssumeRole"
      },
    ]
  })
}

# Kaggle API Layer (仮)
resource "aws_lambda_layer_version" "kaggle_api_layer" {
  layer_name          = "kaggle-api-layer"
  filename            = "/app/build/layer.zip"
  compatible_runtimes = ["python3.11"]
  license_info        = "MIT"
}
