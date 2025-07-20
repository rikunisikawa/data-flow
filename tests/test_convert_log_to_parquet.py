import os
import pytest
import boto3
from moto import mock_aws
import pandas as pd
import pyarrow.parquet as pq
import io
import sys
from unittest.mock import patch, MagicMock

# Add the lambda function path to the sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../convert_log_to_parquet')))

import convert_log_to_parquet

@pytest.fixture
def aws_credentials():
    """Mocked AWS Credentials for moto."""
    os.environ['AWS_ACCESS_KEY_ID'] = 'testing'
    os.environ['AWS_SECRET_ACCESS_KEY'] = 'testing'
    os.environ['AWS_SECURITY_TOKEN'] = 'testing'
    os.environ['AWS_SESSION_TOKEN'] = 'testing'
    os.environ['AWS_DEFAULT_REGION'] = 'us-east-1'

@pytest.fixture
def s3_client(aws_credentials):
    with mock_aws():
        yield boto3.client('s3', region_name='us-east-1')

@pytest.fixture
def mock_env(monkeypatch):
    monkeypatch.setenv('BUCKET_NAME', 'test-bucket')

def test_lambda_handler_success(s3_client, mock_env):
    bucket_name = 'test-bucket'
    s3_client.create_bucket(Bucket=bucket_name)

    # Create a dummy log file and upload to mock S3
    log_content = " ".join(["0.0"] * 24) + "\n"
    s3_client.put_object(Bucket=bucket_name, Key='raw/mHealth_subject1.log', Body=log_content)
    s3_client.put_object(Bucket=bucket_name, Key='raw/not_a_log.txt', Body='some data')

    # Run the handler
    result = convert_log_to_parquet.lambda_handler({}, {})

    # Assertions
    assert result['statusCode'] == 200
    assert 'Successfully converted 1 log files to Parquet' in result['body']
    assert result['convertedFiles'] == ['stage/mHealth_subject1.parquet']

    # Verify the parquet file content
    response = s3_client.get_object(Bucket=bucket_name, Key='stage/mHealth_subject1.parquet')
    parquet_file = pq.read_table(io.BytesIO(response['Body'].read()))
    df = parquet_file.to_pandas()

    assert len(df) == 1
    assert len(df.columns) == 24
    assert list(df.columns) == convert_log_to_parquet.COLUMN_NAMES

def test_lambda_handler_no_log_files(s3_client, mock_env):
    bucket_name = 'test-bucket'
    s3_client.create_bucket(Bucket=bucket_name)
    s3_client.put_object(Bucket=bucket_name, Key='raw/not_a_log.txt', Body='some data')

    result = convert_log_to_parquet.lambda_handler({}, {})

    assert result['statusCode'] == 200
    assert 'Successfully converted 0 log files to Parquet' in result['body']
    assert len(result['convertedFiles']) == 0

def test_lambda_handler_no_env_var():
    result = convert_log_to_parquet.lambda_handler({}, {})
    assert result['statusCode'] == 500
    assert 'Environment variable BUCKET_NAME not set' in result['body']

def test_lambda_handler_s3_error(mock_env):
    # This test will fail because the bucket doesn't exist in the unmocked environment
    # The lambda function should catch the exception and return a 500 error.
    with patch('convert_log_to_parquet.get_s3_client') as mock_get_s3:
        mock_s3 = MagicMock()
        mock_s3.list_objects_v2.side_effect = Exception("S3 Error")
        mock_get_s3.return_value = mock_s3

        result = convert_log_to_parquet.lambda_handler({}, {})
        assert result['statusCode'] == 500
        assert 'Error: S3 Error' in result['body']
