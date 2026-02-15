resource "aws_iam_user" "superset_readonly" {
  name = "${terraform.workspace}-superset-readonly"
}

resource "aws_iam_policy" "superset_readonly" {
  name        = "${terraform.workspace}-superset-readonly"
  description = "Read-only access for Superset to query Athena and read Glue/S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:ListQueryExecutions",
          "athena:GetWorkGroup"
        ]
        Resource = [
          "arn:aws:athena:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:workgroup/${var.athena_workgroup}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "athena:GetDataCatalog",
          "athena:GetDatabase",
          "athena:GetTableMetadata"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetTableVersions",
          "glue:GetPartition",
          "glue:GetPartitions"
        ]
        Resource = [
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/${local.dbt_processed_schema}",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${local.dbt_processed_schema}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "superset_readonly" {
  user       = aws_iam_user.superset_readonly.name
  policy_arn = aws_iam_policy.superset_readonly.arn
}

resource "aws_iam_access_key" "superset_readonly" {
  user = aws_iam_user.superset_readonly.name
}

resource "random_password" "superset_secret_key" {
  length  = 48
  special = true
}

resource "aws_ssm_parameter" "superset_athena_access_key_id" {
  name  = "/data-flow/${terraform.workspace}/superset/athena/access_key_id"
  type  = "SecureString"
  value = aws_iam_access_key.superset_readonly.id
}

resource "aws_ssm_parameter" "superset_athena_secret_access_key" {
  name  = "/data-flow/${terraform.workspace}/superset/athena/secret_access_key"
  type  = "SecureString"
  value = aws_iam_access_key.superset_readonly.secret
}

resource "aws_ssm_parameter" "superset_secret_key" {
  name  = "/data-flow/${terraform.workspace}/superset/secret_key"
  type  = "SecureString"
  value = random_password.superset_secret_key.result
}
