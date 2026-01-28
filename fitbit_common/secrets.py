import json

import boto3


def get_secret_json(secret_arn):
    client = boto3.client("secretsmanager")
    response = client.get_secret_value(SecretId=secret_arn)
    secret = response.get("SecretString")
    if not secret:
        raise ValueError("Secret is empty")
    return json.loads(secret)
