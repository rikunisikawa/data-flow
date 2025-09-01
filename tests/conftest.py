import os
import boto3
import json
import pytest
from moto import mock_aws

@pytest.fixture(scope="function")
def aws_credentials():
    """Mocked AWS Credentials for moto."""
    os.environ["AWS_ACCESS_KEY_ID"] = "testing"
    os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
    os.environ["AWS_SECURITY_TOKEN"] = "testing"
    os.environ["AWS_SESSION_TOKEN"] = "testing"
    os.environ["AWS_DEFAULT_REGION"] = "us-east-1"

@pytest.fixture(scope="function")
def aws_client(aws_credentials):
    """Generic boto3 client mock."""
    with mock_aws():
        yield boto3.client
        
@pytest.fixture
def s3_client(aws_credentials):
    """Mocked S3 client."""
    with mock_aws():
        yield boto3.client("s3", region_name="us-east-1")

@pytest.fixture
def lambda_client(aws_credentials):
    """Mocked Lambda client."""
    with mock_aws():
        yield boto3.client("lambda", region_name="us-east-1")

@pytest.fixture
def iam_client(aws_credentials):
    """Mocked IAM client."""
    with mock_aws():
        yield boto3.client("iam", region_name="us-east-1")

@pytest.fixture
def stepfunctions_client(aws_credentials):
    """Mocked Step Functions client."""
    with mock_aws():
        yield boto3.client("stepfunctions", region_name="us-east-1")

@pytest.fixture
def glue_client(aws_credentials):
    """Mocked Glue client."""
    with mock_aws():
        yield boto3.client("glue", region_name="us-east-1")

@pytest.fixture
def iam_role(iam_client):
    """Create a mock IAM role for Lambda and Glue."""
    role_policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {"Service": ["lambda.amazonaws.com", "glue.amazonaws.com"]},
                "Action": "sts:AssumeRole",
            }
        ],
    }
    response = iam_client.create_role(
        RoleName="test-role", AssumeRolePolicyDocument=json.dumps(role_policy)
    )
    return response["Role"]["Arn"]