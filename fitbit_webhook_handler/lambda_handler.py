import base64
import hmac
import json
import logging
import os
from hashlib import sha1

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def _get_secret():
    secret_arn = os.environ.get("WEBHOOK_SECRET_ARN")
    if not secret_arn:
        raise ValueError("WEBHOOK_SECRET_ARN is not set")
    client = boto3.client("secretsmanager")
    response = client.get_secret_value(SecretId=secret_arn)
    secret = response.get("SecretString")
    if not secret:
        raise ValueError("Webhook secret is empty")
    return secret


def _verify_signature(secret, raw_body, signature_header):
    digest = hmac.new(secret.encode("utf-8"), raw_body, sha1).digest()
    expected = base64.b64encode(digest).decode("utf-8")
    return hmac.compare_digest(expected, signature_header)


def _parse_body(event):
    if event.get("isBase64Encoded"):
        return base64.b64decode(event.get("body") or "")
    return (event.get("body") or "").encode("utf-8")


def lambda_handler(event, context):
    try:
        raw_body = _parse_body(event)
        signature = (event.get("headers") or {}).get("x-fitbit-signature")
        if not signature:
            logger.warning(json.dumps({"message": "Missing signature header"}))
            return {"statusCode": 400, "body": "Missing signature"}

        secret = _get_secret()
        if not _verify_signature(secret, raw_body, signature):
            logger.warning(json.dumps({"message": "Invalid signature"}))
            return {"statusCode": 401, "body": "Invalid signature"}

        payload = json.loads(raw_body.decode("utf-8"))
        queue_url = os.environ["QUEUE_URL"]
        sqs = boto3.client("sqs")

        messages = payload if isinstance(payload, list) else [payload]
        for message in messages:
            body = json.dumps(message, ensure_ascii=False)
            sqs.send_message(QueueUrl=queue_url, MessageBody=body)

        logger.info(json.dumps({"message": "Webhook accepted", "count": len(messages)}))
        return {"statusCode": 200, "body": "ok"}
    except Exception as exc:
        logger.exception(json.dumps({"message": "Webhook handler failed", "error": str(exc)}))
        return {"statusCode": 500, "body": f"Error: {exc}"}
