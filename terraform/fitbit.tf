locals {
  fitbit_raw_prefix = "raw/fitbit/"
}

resource "aws_secretsmanager_secret" "fitbit_oauth" {
  name = "${terraform.workspace}/fitbit/oauth"
}

resource "aws_secretsmanager_secret_version" "fitbit_oauth" {
  secret_id = aws_secretsmanager_secret.fitbit_oauth.id
  secret_string = jsonencode({
    client_id     = var.fitbit_client_id
    client_secret = var.fitbit_client_secret
  })
}

resource "aws_secretsmanager_secret" "fitbit_webhook" {
  name = "${terraform.workspace}/fitbit/webhook"
}

resource "aws_secretsmanager_secret_version" "fitbit_webhook" {
  secret_id     = aws_secretsmanager_secret.fitbit_webhook.id
  secret_string = var.fitbit_webhook_secret
}

resource "aws_dynamodb_table" "fitbit_tokens" {
  name         = "${terraform.workspace}-fitbit-tokens"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "fitbit_user_id"
    type = "S"
  }

  global_secondary_index {
    name            = "fitbit_user_id_index"
    hash_key        = "fitbit_user_id"
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled = true
  }
}

resource "aws_sqs_queue" "fitbit_webhook_dlq" {
  name = "${terraform.workspace}-fitbit-webhook-dlq"
}

resource "aws_sqs_queue" "fitbit_webhook_queue" {
  name = "${terraform.workspace}-fitbit-webhook-queue"
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.fitbit_webhook_dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_iam_role" "fitbit_firehose_role" {
  name = "${terraform.workspace}-fitbit-firehose-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "fitbit_firehose_policy" {
  name = "${terraform.workspace}-fitbit-firehose-policy"
  role = aws_iam_role.fitbit_firehose_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = [
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_kinesis_firehose_delivery_stream" "fitbit_raw" {
  name        = "${terraform.workspace}-fitbit-raw"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.fitbit_firehose_role.arn
    bucket_arn = aws_s3_bucket.this.arn

    prefix              = "${local.fitbit_raw_prefix}event_type=!{partitionKeyFromQuery:event_type}/dt=!{timestamp:yyyy-MM-dd}/hour=!{timestamp:HH}/"
    error_output_prefix = "${local.fitbit_raw_prefix}errors/!{firehose:error-output-type}/dt=!{timestamp:yyyy-MM-dd}/"

    buffering_interval = 60
    buffering_size     = 5

    compression_format = "UNCOMPRESSED"

    dynamic_partitioning_configuration {
      enabled = true
    }

    processing_configuration {
      enabled = true

      processors {
        type = "MetadataExtraction"

        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{event_type:.event_type}"
        }

        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
      }
    }
  }
}

resource "aws_iam_role" "fitbit_webhook_role" {
  name = "${terraform.workspace}-fitbit-webhook-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "fitbit_webhook_policy" {
  name = "${terraform.workspace}-fitbit-webhook-policy"
  role = aws_iam_role.fitbit_webhook_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.fitbit_webhook_queue.arn
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.fitbit_webhook.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role" "fitbit_fetcher_role" {
  name = "${terraform.workspace}-fitbit-fetcher-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "fitbit_fetcher_policy" {
  name = "${terraform.workspace}-fitbit-fetcher-policy"
  role = aws_iam_role.fitbit_fetcher_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          aws_dynamodb_table.fitbit_tokens.arn,
          "${aws_dynamodb_table.fitbit_tokens.arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.fitbit_oauth.arn
      },
      {
        Effect = "Allow"
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ]
        Resource = aws_kinesis_firehose_delivery_stream.fitbit_raw.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.fitbit_webhook_queue.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role" "fitbit_poller_role" {
  name = "${terraform.workspace}-fitbit-poller-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "fitbit_poller_policy" {
  name = "${terraform.workspace}-fitbit-poller-policy"
  role = aws_iam_role.fitbit_poller_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.fitbit_tokens.arn
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.fitbit_oauth.arn
      },
      {
        Effect = "Allow"
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ]
        Resource = aws_kinesis_firehose_delivery_stream.fitbit_raw.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

module "fitbit_webhook_lambda" {
  source = "./modules/lambda"

  function_name         = "${terraform.workspace}-fitbit-webhook-handler"
  handler               = "fitbit_webhook_handler.lambda_handler"
  runtime               = "python3.11"
  architectures         = ["x86_64"]
  memory_size           = 512
  timeout               = 30
  filename              = "${path.module}/../build/fitbit_webhook_handler.zip"
  role_arn              = aws_iam_role.fitbit_webhook_role.arn
  layers                = []
  environment_variables = {
    QUEUE_URL          = aws_sqs_queue.fitbit_webhook_queue.id
    WEBHOOK_SECRET_ARN = aws_secretsmanager_secret.fitbit_webhook.arn
  }
}

module "fitbit_fetcher_lambda" {
  source = "./modules/lambda"

  function_name         = "${terraform.workspace}-fitbit-fetcher"
  handler               = "fitbit_fetcher.lambda_handler"
  runtime               = "python3.11"
  architectures         = ["x86_64"]
  memory_size           = 1024
  timeout               = 120
  filename              = "${path.module}/../build/fitbit_fetcher.zip"
  role_arn              = aws_iam_role.fitbit_fetcher_role.arn
  layers                = []
  environment_variables = {
    TOKENS_TABLE            = aws_dynamodb_table.fitbit_tokens.name
    FITBIT_OAUTH_SECRET_ARN = aws_secretsmanager_secret.fitbit_oauth.arn
    FIREHOSE_STREAM_NAME    = aws_kinesis_firehose_delivery_stream.fitbit_raw.name
  }
}

module "fitbit_poller_lambda" {
  source = "./modules/lambda"

  function_name         = "${terraform.workspace}-fitbit-poller"
  handler               = "fitbit_poller.lambda_handler"
  runtime               = "python3.11"
  architectures         = ["x86_64"]
  memory_size           = 1024
  timeout               = 300
  filename              = "${path.module}/../build/fitbit_poller.zip"
  role_arn              = aws_iam_role.fitbit_poller_role.arn
  layers                = []
  environment_variables = {
    TOKENS_TABLE            = aws_dynamodb_table.fitbit_tokens.name
    FITBIT_OAUTH_SECRET_ARN = aws_secretsmanager_secret.fitbit_oauth.arn
    FIREHOSE_STREAM_NAME    = aws_kinesis_firehose_delivery_stream.fitbit_raw.name
    POLL_LOOKBACK_MINUTES   = var.fitbit_poll_lookback_minutes
    MIN_POLL_INTERVAL_SECONDS = var.fitbit_min_poll_interval_seconds
    SHARD_ID                = var.fitbit_poller_shard_id
    SHARD_COUNT             = var.fitbit_poller_shard_count
  }
}

resource "aws_lambda_event_source_mapping" "fitbit_fetcher_sqs" {
  event_source_arn = aws_sqs_queue.fitbit_webhook_queue.arn
  function_name    = module.fitbit_fetcher_lambda.function_arn
  batch_size       = 10
  enabled          = true
  function_response_types = ["ReportBatchItemFailures"]
}

resource "aws_apigatewayv2_api" "fitbit_webhook" {
  name          = "${terraform.workspace}-fitbit-webhook"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "fitbit_webhook" {
  api_id           = aws_apigatewayv2_api.fitbit_webhook.id
  integration_type = "AWS_PROXY"
  integration_uri  = module.fitbit_webhook_lambda.function_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "fitbit_webhook" {
  api_id    = aws_apigatewayv2_api.fitbit_webhook.id
  route_key = "POST /webhooks/fitbit"
  target    = "integrations/${aws_apigatewayv2_integration.fitbit_webhook.id}"
}

resource "aws_apigatewayv2_stage" "fitbit_webhook" {
  api_id      = aws_apigatewayv2_api.fitbit_webhook.id
  name        = "${terraform.workspace}"
  auto_deploy = true
}

resource "aws_lambda_permission" "fitbit_webhook" {
  statement_id  = "AllowAPIGatewayInvokeFitbitWebhook"
  action        = "lambda:InvokeFunction"
  function_name = module.fitbit_webhook_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.fitbit_webhook.execution_arn}/*/*"
}

resource "aws_iam_role" "fitbit_scheduler_role" {
  name = "${terraform.workspace}-fitbit-scheduler-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "fitbit_scheduler_policy" {
  name = "${terraform.workspace}-fitbit-scheduler-policy"
  role = aws_iam_role.fitbit_scheduler_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = module.fitbit_poller_lambda.function_arn
      }
    ]
  })
}

resource "aws_scheduler_schedule" "fitbit_poller" {
  name       = "${terraform.workspace}-fitbit-poller"
  group_name = "default"
  schedule_expression = var.fitbit_poll_schedule

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = module.fitbit_poller_lambda.function_arn
    role_arn = aws_iam_role.fitbit_scheduler_role.arn
  }
}

resource "aws_glue_catalog_database" "fitbit_raw" {
  name = "${terraform.workspace}_fitbit_raw"
}

resource "aws_glue_catalog_table" "fitbit_raw_events" {
  database_name = aws_glue_catalog_database.fitbit_raw.name
  name          = "raw_events"
  table_type    = "EXTERNAL_TABLE"

  partition_keys {
    name = "event_type"
    type = "string"
  }

  partition_keys {
    name = "dt"
    type = "string"
  }

  partition_keys {
    name = "hour"
    type = "string"
  }

  parameters = {
    classification = "json"
    EXTERNAL       = "TRUE"
    "projection.enabled"             = "true"
    "projection.event_type.type"     = "enum"
    "projection.event_type.values"   = "activity,sleep,body,foods,weight,heart_rate_intraday"
    "projection.dt.type"             = "date"
    "projection.dt.format"           = "yyyy-MM-dd"
    "projection.dt.range"            = "2020-01-01,NOW"
    "projection.hour.type"           = "integer"
    "projection.hour.range"          = "0,23"
    "storage.location.template"      = "s3://${aws_s3_bucket.this.bucket}/${local.fitbit_raw_prefix}event_type=$${event_type}/dt=$${dt}/hour=$${hour}/"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.this.bucket}/${local.fitbit_raw_prefix}"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "json-serde"
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name = "event_id"
      type = "string"
    }

    columns {
      name = "source"
      type = "string"
    }

    columns {
      name = "user_id"
      type = "string"
    }

    columns {
      name = "fitbit_user_id"
      type = "string"
    }

    columns {
      name = "event_type"
      type = "string"
    }

    columns {
      name = "event_time"
      type = "string"
    }

    columns {
      name = "ingest_time"
      type = "string"
    }

    columns {
      name = "schema_version"
      type = "string"
    }

    columns {
      name = "payload"
      type = "string"
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "fitbit_webhook_errors" {
  alarm_name          = "${terraform.workspace}-fitbit-webhook-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  dimensions = {
    FunctionName = module.fitbit_webhook_lambda.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "fitbit_fetcher_errors" {
  alarm_name          = "${terraform.workspace}-fitbit-fetcher-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  dimensions = {
    FunctionName = module.fitbit_fetcher_lambda.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "fitbit_poller_errors" {
  alarm_name          = "${terraform.workspace}-fitbit-poller-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  dimensions = {
    FunctionName = module.fitbit_poller_lambda.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "fitbit_webhook_dlq" {
  alarm_name          = "${terraform.workspace}-fitbit-webhook-dlq"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  dimensions = {
    QueueName = aws_sqs_queue.fitbit_webhook_dlq.name
  }
}
