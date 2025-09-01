import boto3
import json

def create_iam_role_for_lambda(iam_client, role_name="test-lambda-role"):
    """Creates a mock IAM role for Lambda functions."""
    try:
        response = iam_client.create_role(
            RoleName=role_name,
            AssumeRolePolicyDocument=json.dumps({
                "Version": "2012-10-17",
                "Statement": [{
                    "Effect": "Allow",
                    "Principal": {"Service": "lambda.amazonaws.com"},
                    "Action": "sts:AssumeRole"
                }]
            })
        )
        return response['Role']['Arn']
    except iam_client.exceptions.EntityAlreadyExistsException:
        response = iam_client.get_role(RoleName=role_name)
        return response['Role']['Arn']

def create_mock_lambda(lambda_client, function_name, role_arn):
    """Creates a mock Lambda function."""
    zip_content = b"def handler(event, context): return {'statusCode': 200, 'body': 'mock success'}"
    
    response = lambda_client.create_function(
        FunctionName=function_name,
        Runtime='python3.11',
        Role=role_arn,
        Handler='index.handler',
        Code={'ZipFile': zip_content},
        Description='Mock Lambda for testing',
        Timeout=3,
        MemorySize=128
    )
    return response['FunctionArn']

def create_mock_lambdas(lambda_client, iam_role_arn):
    """Creates all necessary mock Lambdas for the state machine."""
    arns = {}
    lambda_names = ["DownloadAndUpload", "ConvertLogToParquet"] # Add other lambda names
    for name in lambda_names:
        arns[name] = create_mock_lambda(lambda_client, name, iam_role_arn)
    return arns
