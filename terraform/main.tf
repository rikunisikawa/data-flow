locals {
  bucket_name = "${terraform.workspace}-${var.base_bucket_name}"
}

data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "kaggle_username" {
  name = "/data-flow/kaggle/username"
  with_decryption = true
}

data "aws_ssm_parameter" "kaggle_key" {
  name = "/data-flow/kaggle/key"
  with_decryption = true
}

resource "aws_s3_bucket" "this" {
  bucket = local.bucket_name
}

resource "aws_s3_object" "glue_script" {
  bucket = aws_s3_bucket.this.id
  key    = "scripts/glue_job.py"
  source = "/app/glue_job/glue_job.py"
  etag   = filemd5("/app/glue_job/glue_job.py")
}

module "download_and_upload_lambda" {
  source = "./modules/lambda"

  function_name         = "${terraform.workspace}-download-and-upload-function"
  handler               = "download_and_upload.lambda_handler"
  runtime               = "python3.11"
  architectures         = ["x86_64"]
  memory_size           = 1024
  timeout               = 300
  filename              = "/app/build/download_and_upload.zip"
  role_arn              = aws_iam_role.lambda_execution_role.arn
  layers                = [aws_lambda_layer_version.kaggle_api_layer.arn]
  environment_variables = {
    BUCKET_NAME     = local.bucket_name
    KAGGLE_USERNAME = data.aws_ssm_parameter.kaggle_username.value
    KAGGLE_KEY      = data.aws_ssm_parameter.kaggle_key.value
  }
}

module "convert_log_to_parquet_lambda" {
  source = "./modules/lambda"

  function_name         = "${terraform.workspace}-convert-log-to-parquet-function"
  handler               = "convert_log_to_parquet.lambda_handler"
  runtime               = "python3.11"
  architectures         = ["x86_64"]
  memory_size           = 1024
  timeout               = 300
  filename              = "/app/build/convert_log_to_parquet.zip"
  role_arn              = aws_iam_role.lambda_execution_role.arn
  layers                = [aws_lambda_layer_version.kaggle_api_layer.arn]
  environment_variables = {
    BUCKET_NAME = local.bucket_name
  }
}

# Lambda実行ロール (仮)
resource "aws_iam_role" "lambda_execution_role" {
  name               = "${terraform.workspace}-lambda-execution-role"
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

resource "aws_iam_role_policy" "lambda_execution_policy" {
  name = "${terraform.workspace}-lambda-execution-policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = "${aws_s3_bucket.this.arn}/*"
      },
      {
        Effect = "Allow",
        Action = "s3:ListBucket",
        Resource = aws_s3_bucket.this.arn
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Kaggle API Layer (仮)
resource "aws_lambda_layer_version" "kaggle_api_layer" {
  layer_name          = "${terraform.workspace}-kaggle-api-layer"
  s3_bucket           = aws_s3_bucket.this.id # S3バケットを参照
  s3_key              = "layers/layer.zip"    # S3上のキー
  source_code_hash    = filebase64sha256("/app/build/layer.zip") # ハッシュで更新をトリガー
  compatible_runtimes = ["python3.11"]
  license_info        = "MIT"
}

resource "aws_sfn_state_machine" "data_processing_state_machine" {
  name     = "${terraform.workspace}-data-processing-state-machine"
  role_arn = aws_iam_role.sfn_execution_role.arn

  definition = templatefile("/app/state_machine/data_processing.asl.json", {
    DownloadAndUploadFunctionArn   = module.download_and_upload_lambda.function_arn
    ConvertLogToParquetFunctionArn = module.convert_log_to_parquet_lambda.function_arn
    GlueJobName                    = "" # Not used anymore
    BucketName                     = local.bucket_name
  })
}

resource "aws_iam_role" "sfn_execution_role" {
  name = "${terraform.workspace}-sfn-execution-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "StepFunctionsExecutionPolicy"
    policy = jsonencode({
      Version   = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "lambda:InvokeFunction"
          Resource = [
            module.download_and_upload_lambda.function_arn,
            module.convert_log_to_parquet_lambda.function_arn,
          ]
        }
      ]
    })
  }
}

# Role for GitHub Actions to assume for Terraform deployment
resource "aws_iam_role" "github_actions_terraform_deploy_role" {
  name = "GitHubActionsTerraformDeployRole"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:rikunisikawa/data-flow:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_actions_terraform_deploy_policy" {
  name = "GitHubActionsTerraformDeployPolicy"
  role = aws_iam_role.github_actions_terraform_deploy_role.id

  # WARNING: This policy is highly permissive.
  # For production environments, it is strongly recommended to scope down these permissions
  # to the minimum required for your Terraform resources.
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:*",
          "lambda:*",
          "iam:*",
          "states:*"
        ]
        Resource = "*"
      }
    ]
  })
}
