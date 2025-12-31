locals {
  dbt_container_name   = "dbt-cli"
  dbt_processed_schema = "${terraform.workspace}_processed"
  dbt_stage_database   = "${terraform.workspace}_stage_mhealth"
}

data "aws_region" "current" {}

resource "aws_ecr_repository" "dbt" {
  name                 = "${terraform.workspace}-data-platform/dbt"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "${terraform.workspace}-dbt"
    Environment = terraform.workspace
  }
}

resource "aws_ecs_cluster" "dbt" {
  name = "${terraform.workspace}-dbt-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${terraform.workspace}-dbt-cluster"
    Environment = terraform.workspace
  }
}

resource "aws_cloudwatch_log_group" "dbt" {
  name              = "/ecs/${terraform.workspace}/dbt"
  retention_in_days = 30

  tags = {
    Name        = "${terraform.workspace}-dbt-logs"
    Environment = terraform.workspace
  }
}

resource "aws_security_group" "dbt_tasks" {
  name        = "${terraform.workspace}-dbt-fargate-sg"
  description = "Security group for dbt Fargate tasks"
  vpc_id      = aws_vpc.dbt.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${terraform.workspace}-dbt-fargate-sg"
    Environment = terraform.workspace
  }
}

resource "aws_iam_role" "dbt_task_execution" {
  name = "${terraform.workspace}-dbt-task-execution-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${terraform.workspace}-dbt-task-execution-role"
    Environment = terraform.workspace
  }
}

resource "aws_iam_role_policy_attachment" "dbt_task_execution_ecs" {
  role       = aws_iam_role.dbt_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "dbt_task" {
  name = "${terraform.workspace}-dbt-task-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${terraform.workspace}-dbt-task-role"
    Environment = terraform.workspace
  }
}

resource "aws_iam_policy" "dbt_task" {
  name        = "${terraform.workspace}-dbt-task-policy"
  description = "Permissions for dbt Fargate task to interact with Glue, Athena, and S3"

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.this.arn}",
          "${aws_s3_bucket.this.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:StopQueryExecution",
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
          "glue:GetPartitions",
          "glue:CreateDatabase",
          "glue:CreateTable",
          "glue:UpdateTable",
          "glue:DeleteTable"
        ]
        Resource = [
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/${local.dbt_stage_database}",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/${local.dbt_processed_schema}",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/elementary",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/${local.dbt_processed_schema}_elementary",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${local.dbt_stage_database}/*",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${local.dbt_processed_schema}/*",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/elementary/*",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${local.dbt_processed_schema}_elementary/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dbt_task_policy" {
  role       = aws_iam_role.dbt_task.name
  policy_arn = aws_iam_policy.dbt_task.arn
}

resource "aws_ecs_task_definition" "dbt" {
  family                   = "${terraform.workspace}-dbt-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.dbt_task_cpu
  memory                   = var.dbt_task_memory
  execution_role_arn       = aws_iam_role.dbt_task_execution.arn
  task_role_arn            = aws_iam_role.dbt_task.arn

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([
    {
      name      = local.dbt_container_name
      image     = "${aws_ecr_repository.dbt.repository_url}:${var.dbt_image_tag}"
      essential = true
      entryPoint = [
        "/bin/sh",
        "-c"
      ]
      command = [
        "dbt deps && /work/data_flow_dbt/scripts/apply_elementary_patches.sh && dbt run && dbt test && dbt build --select elementary && mkdir -p /work/data_flow_dbt/elementary_reports/monitoring-reports && edr monitor report --config-dir /work/data_flow_dbt --profiles-dir /work/.dbt --project-dir /work/data_flow_dbt --profile-target dev --days-back 7 --output-path /work/data_flow_dbt/elementary_reports/monitoring-reports && aws s3 sync /work/data_flow_dbt/elementary_reports/monitoring-reports/ s3://${aws_s3_bucket.this.id}/processed/elementary-reports/latest/ --delete && aws s3 cp /work/data_flow_dbt/elementary_reports/monitoring-reports/elementary_report.html s3://${aws_s3_bucket.this.id}/processed/elementary-reports/latest/index.html"
      ]
      workingDirectory = "/work/data_flow_dbt"
      environment = [
        { name = "DBT_PROFILES_DIR", value = "/work/dbt_profiles" },
        { name = "AWS_REGION", value = data.aws_region.current.name },
        { name = "AWS_DEFAULT_REGION", value = data.aws_region.current.name },
        { name = "ATHENA_WORK_GROUP", value = var.athena_workgroup },
        { name = "GLUE_STAGE_DATABASE", value = local.dbt_stage_database },
        { name = "DBT_SCHEMA", value = local.dbt_processed_schema },
        { name = "ELEMENTARY_SCHEMA", value = "elementary" },
        { name = "S3_STAGING_DIR", value = "s3://${aws_s3_bucket.this.id}/athena/staging/" },
        { name = "S3_DATA_DIR", value = "s3://${aws_s3_bucket.this.id}/processed/" },
        { name = "BUCKET", value = aws_s3_bucket.this.id }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.dbt.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "dbt"
        }
      }
    }
  ])

  tags = {
    Name        = "${terraform.workspace}-dbt-task"
    Environment = terraform.workspace
  }
}

locals {
  dbt_subnet_ids = [for subnet in aws_subnet.dbt_public : subnet.id]
}
