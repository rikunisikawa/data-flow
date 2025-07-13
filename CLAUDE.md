# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an AWS serverless data platform built with SAM (Serverless Application Model) that processes Kaggle mHealth dataset files through an ETL pipeline. The system downloads log files from Kaggle, converts them to Parquet format, and stores them in S3 for analysis with Athena.

## Architecture

### Data Flow
1. **Lambda① (download_and_upload)**: Downloads mHealth dataset from Kaggle → saves to S3 `/raw/`
2. **Lambda② (convert_csv_to_parquet)**: Converts CSV/log files to Parquet → saves to S3 `/stage/`
3. **Glue Job**: Data transformation and catalog registration → saves to S3 `/processed/`
4. **Athena**: Query interface for analysis

### S3 Structure
```
s3://aws-data-platform-20250607/
├── raw/         # Raw CSV/log files from Kaggle
├── stage/       # Converted Parquet files
└── processed/   # Cleaned and cataloged Parquet files
```

## Key Files

- `template.yaml`: SAM infrastructure template
- `download_and_upload/download_and_upload.py`: Kaggle data download Lambda
- `convert_log_to_parquet/convert_log_to_parquet.py`: log to Parquet conversion Lambda
- `glue_job/glue_job.py`: AWS Glue job for data transformation
- `layer/python/requirements.txt`: Python dependencies for Lambda layer

## Development Commands

### Build and Deploy
```bash
sam build
sam deploy --guided
```

### Local Testing
```bash
sam local invoke DownloadAndUploadFunction
sam local invoke ConvertLogToParquetFunction
```

### Dependencies Installation
The project uses a Lambda layer for shared dependencies. Install dependencies into the layer:
```bash
pip install -r layer/python/requirements.txt -t layer/python/
```

## Environment Variables

- `BUCKET_NAME`: S3 bucket for data storage (aws-data-platform-20250607)
- `KAGGLE_USERNAME`: Kaggle API username
- `KAGGLE_KEY`: Kaggle API key

## Dependencies

Core Python packages used:
- `boto3`: AWS SDK
- `pandas`: Data manipulation
- `pyarrow`: Parquet file handling
- `kaggle`: Kaggle API client
- `numpy`: Numerical computations

## Data Processing Notes

- The original design expected CSV files but the actual Kaggle dataset contains log files
- Lambda functions handle file format conversion from CSV/log to Parquet
- Glue job performs schema normalization and data catalog registration
- Athena queries are supported through Glue Data Catalog integration