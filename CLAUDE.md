# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AWS serverless data platform that processes the Kaggle mHealth dataset through a multi-stage ETL pipeline. Raw `.log` files are downloaded from Kaggle, converted to Parquet, transformed via dbt on Athena, and made queryable through Glue Data Catalog. Infrastructure is managed with Terraform (primary) and deployed via GitHub Actions CI/CD.

## Architecture

### Data Flow (Step Functions Pipeline)

```
EventBridge (daily) → Step Functions:
  1. Lambda① (download_and_upload) → S3 /raw/
  2. Lambda② (convert_log_to_parquet) → S3 /stage/ (partitioned Parquet)
  3. ECS Fargate (dbt) → S3 /processed/ (transformed tables)
                       → Elementary reports (data quality)
  4. Athena → Query via Glue Data Catalog
```

### S3 Structure

```
s3://{workspace}-aws-data-platform-20250607/
├── raw/              # Raw .log files from Kaggle
├── stage/            # Parquet files partitioned by subject_id/activity_label
├── processed/        # dbt-transformed Parquet tables
├── athena/staging/   # Athena query results
├── scripts/          # Glue job script
├── layers/           # Lambda layer zip
└── dbt-temp/         # dbt temporary staging
```

### AWS Services Used

Lambda, S3, Step Functions, EventBridge, Glue (Data Catalog), Athena, ECS Fargate, ECR, CloudFront, Cognito, IAM, SSM Parameter Store, VPC

## Directory Structure

```
├── download_and_upload/          # Lambda①: Kaggle download
├── convert_log_to_parquet/       # Lambda②: log-to-Parquet conversion
├── glue_job/                     # Glue ETL script (legacy, replaced by dbt)
├── data_flow_dbt/                # dbt project for Athena transformations
│   ├── models/                   #   SQL models (cleaned_activities, etc.)
│   ├── tests/                    #   dbt data tests
│   ├── elementary_config.yml     #   Data quality monitoring config
│   └── dbt_project.yml
├── docker/                       # Docker configs for dbt Fargate task
├── dbt_profiles/                 # dbt connection profiles
├── state_machine/                # Step Functions ASL definition
├── terraform/                    # Infrastructure as Code (primary IaC)
│   ├── modules/                  #   Reusable modules (lambda, iam, glue_*)
│   ├── main.tf                   #   Core resources
│   ├── ecs.tf                    #   ECS Fargate for dbt
│   ├── network.tf                #   VPC networking
│   ├── cognito.tf                #   Cognito auth (Elementary reports)
│   ├── cloudfront_reports.tf     #   CloudFront distribution
│   ├── edge_auth.tf              #   CloudFront edge auth Lambda
│   └── dev.tfvars / prod.tfvars  #   Environment-specific variables
├── layer/                        # Lambda layer build (Docker-based)
│   ├── src/Dockerfile            #   Multi-stage build for x86_64
│   ├── src/requirements.txt      #   Production Python deps
│   └── terraform/build-layer.sh  #   Layer build script
├── tests/                        # Python unit tests (pytest + moto)
├── .github/workflows/            # CI/CD pipelines
├── ai-doc/                       # Architecture docs, troubleshooting
├── specs/                        # Spec Kit issue plans
├── notebooks/                    # Jupyter EDA notebooks
├── scripts/                      # Helper scripts
├── template.yaml                 # SAM template (legacy reference only)
└── build.sh                      # Build Lambda deployment packages
```

## Development Commands

### Build Lambda Packages

```bash
# Build all Lambda zips and layer (requires Docker)
bash build.sh

# Output: build/download_and_upload.zip, build/convert_log_to_parquet.zip, build/layer.zip
```

### Terraform Deploy

```bash
# Dev environment
cd terraform
terraform workspace select dev
terraform apply -var-file=dev.tfvars

# Production deploys should go through CI/CD (push to main)
```

### Run Tests

```bash
pip install -r tests/requirements.txt
pytest tests/
```

### Local Lambda Testing (SAM — legacy)

```bash
sam build
sam local invoke DownloadAndUploadFunction
sam local invoke ConvertLogToParquetFunction
```

### dbt

```bash
cd data_flow_dbt
dbt run --profiles-dir ../dbt_profiles
dbt test --profiles-dir ../dbt_profiles
```

## Key Source Files

| File | Purpose |
|------|---------|
| `download_and_upload/download_and_upload.py` | Lambda①: Downloads mHealth dataset from Kaggle, uploads `.log` files to S3 `/raw/` |
| `convert_log_to_parquet/convert_log_to_parquet.py` | Lambda②: Reads `.log` files from `/raw/`, converts to Parquet partitioned by `subject_id`/`activity_label`, writes to `/stage/` |
| `glue_job/glue_job.py` | Glue ETL script for column normalization (legacy — dbt now handles transformation) |
| `data_flow_dbt/models/cleaned_activities.sql` | dbt model: extracts `user_id` from path, computes 3-axis accelerometer averages, filters null class |
| `state_machine/data_processing.asl.json` | Step Functions definition: Download → Convert → RunDbtTask (ECS Fargate) |
| `terraform/main.tf` | Core Terraform config: S3, Lambda, Layer, Step Functions, IAM, Glue Catalog |
| `terraform/ecs.tf` | ECS Fargate cluster/task definition for dbt |
| `build.sh` | Builds Lambda deployment zips and layer |

## Environment Variables

### Lambda

- `BUCKET_NAME`: S3 bucket name (workspace-prefixed, e.g., `dev-aws-data-platform-20250607`)
- `KAGGLE_USERNAME`: Kaggle API username (injected from SSM Parameter Store)
- `KAGGLE_KEY`: Kaggle API key (injected from SSM Parameter Store)

### dbt / Fargate

- `S3_STAGING_DIR`: Athena staging directory
- `S3_DATA_DIR`: Processed data directory
- `AWS_REGION`: `ap-northeast-1`
- `GLUE_STAGE_DATABASE`: Glue database name (e.g., `dev_stage_mhealth`)
- `DBT_SCHEMA`: Output schema (e.g., `dev_processed`)
- `ELEMENTARY_SCHEMA`: Elementary schema name

## Dependencies

### Production (Lambda Layer — `layer/src/requirements.txt`)

- `pandas` — data manipulation
- `fastparquet` — Parquet serialization
- `kaggle` — Kaggle API client
- `numpy==1.26.4` — numerical computing
- `boto3` — AWS SDK (available in Lambda runtime, commented out in requirements)

### Test (`tests/requirements.txt`)

- `pytest` — test framework
- `moto` — AWS service mocking
- `pyarrow` — Parquet reading/validation
- `boto3`, `pandas`, `fastparquet`

## Data Schema

The mHealth dataset has 24 columns (space-delimited `.log` files). Column names are defined in `convert_log_to_parquet.py`'s `COLUMN_NAMES` list:

- 3 chest accelerometer columns (`chest_acc_x/y/z`)
- 2 chest ECG columns (`chest_ecg_1/2`)
- 9 left ankle sensor columns (accelerometer, gyroscope, magnetometer × 3 axes)
- 9 right lower arm sensor columns (accelerometer, gyroscope, magnetometer × 3 axes)
- 1 activity label (`activity_label`) — `0` = null class (excluded from stage)

### Partitioning

Stage data is partitioned as: `stage/subject_id={id}/activity_label={label}/data_{id}_{label}.parquet`

## Infrastructure as Code

### Terraform (Primary)

- **Workspace strategy**: `dev` and `prod` environments separated by Terraform workspaces
- **Resource naming**: `{workspace}-{resource-name}` prefix convention
- **Modules**: `modules/lambda/`, `modules/iam/`, `modules/glue_catalog/`, `modules/glue_database/`
- **Secrets**: Kaggle credentials stored in SSM Parameter Store (`/data-flow/kaggle/username`, `/data-flow/kaggle/key`)

### SAM (Legacy)

`template.yaml` is retained as a design reference. Terraform is the active IaC. Do not deploy with SAM in production.

## CI/CD

### Main Pipeline (`.github/workflows/terraform-deploy.yml`)

Triggered on push to `main` or manual dispatch:
1. Build Lambda packages (cached)
2. Build and push dbt Docker image to ECR
3. Terraform apply (two-phase: IAM first, then all resources)

Uses OIDC for AWS authentication (no long-lived credentials).

### Auto-PR Pipeline (`.github/workflows/auto-pr.yml`)

Automates issue-to-PR workflow using Gemini CLI for planning and implementation.

## Coding Conventions

### Lambda Functions

- Return `{'statusCode': 200|500, 'body': '...'}` response format
- Use `logging` module for structured single-line log output
- Create boto3 clients in getter functions (`get_s3_client()`) for testability
- No silent exception swallowing — log full stack traces and return 500
- Design for idempotency (safe to re-run)
- Never hardcode credentials — use environment variables from SSM

### Testing

- Unit tests required for all Python changes
- Mock all external services with `moto` (`@mock_aws`) and `unittest.mock.patch`
- Test both success and error paths
- Validate column counts, schema, output paths, and partition keys

### Infrastructure

- All resource names prefixed with Terraform workspace
- Use `.tfvars` files for environment-specific configuration
- Keep IAM policies scoped to minimum required permissions

### Git/PR Rules

- PR titles must include the Issue number (e.g., `feat: description (issue #17)`)
- Commit by feature unit or logical grouping
- **Do not edit `.github/workflows/` files** — these affect CI/CD and require dedicated review

### Response Language

- AI/agent responses should be in Japanese (日本語)
- Code, identifiers, logs, error messages, and standard technical terms may remain in English

## Change Impact Checklist

When making changes, verify these related areas:

- **Schema changes**: Update `COLUMN_NAMES` in Lambda②, Glue Catalog definition in Terraform, dbt models, and tests
- **S3 path changes**: Update Athena external tables, dbt sources, Glue scripts, Terraform S3 references
- **Dependency additions**: Rebuild Lambda layer (`build.sh`), verify layer size and cold start impact
- **Lambda config changes**: Review timeout (300s), memory (1024MB), retry, and concurrency settings
- **IAM changes**: Ensure minimum privilege; scope to specific resources and regions
- **Cost impact**: Consider Lambda execution time, S3 object count, Athena scan volume, Fargate task duration

## Troubleshooting

- Mermaid diagram syntax errors and Jupyter notebook JSON corruption: see `ai-doc/tips/troubleshooting-notebook-mermaid.md`
- ETL flow diagram: `ai-doc/infra/etl_flow.md`
- Terraform design rationale: `ai-doc/infra/terraform-design.md`
- GitHub Actions CI/CD docs: `.github/docs/github-actions/`
