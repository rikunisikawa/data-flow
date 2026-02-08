import base64
import json
import os
import sys
from unittest.mock import MagicMock, patch

import pytest

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from fitbit_webhook_handler import lambda_handler as webhook


def _sign(secret, payload_bytes):
    import hmac
    from hashlib import sha1

    digest = hmac.new(secret.encode("utf-8"), payload_bytes, sha1).digest()
    return base64.b64encode(digest).decode("utf-8")


@pytest.fixture
def env_vars(monkeypatch):
    monkeypatch.setenv("QUEUE_URL", "https://sqs.example/queue")
    monkeypatch.setenv("WEBHOOK_SECRET_ARN", "arn:aws:secretsmanager:region:123:secret:fitbit")


def test_webhook_handler_success(env_vars):
    payload = [{"ownerId": "123", "collectionType": "activities", "date": "2024-01-01"}]
    raw_body = json.dumps(payload).encode("utf-8")
    signature = _sign("secret", raw_body)

    event = {
        "body": raw_body.decode("utf-8"),
        "headers": {"x-fitbit-signature": signature},
        "isBase64Encoded": False,
    }

    mock_secrets = MagicMock()
    mock_secrets.get_secret_value.return_value = {"SecretString": "secret"}
    mock_sqs = MagicMock()

    with patch("boto3.client") as mock_client:
        mock_client.side_effect = [mock_secrets, mock_sqs]
        response = webhook.lambda_handler(event, {})

    assert response["statusCode"] == 200
    mock_sqs.send_message.assert_called_once()


def test_webhook_handler_invalid_signature(env_vars):
    payload = [{"ownerId": "123"}]
    raw_body = json.dumps(payload).encode("utf-8")
    signature = _sign("secret", raw_body)

    event = {
        "body": raw_body.decode("utf-8"),
        "headers": {"x-fitbit-signature": signature + "invalid"},
        "isBase64Encoded": False,
    }

    mock_secrets = MagicMock()
    mock_secrets.get_secret_value.return_value = {"SecretString": "secret"}

    with patch("boto3.client") as mock_client:
        mock_client.return_value = mock_secrets
        response = webhook.lambda_handler(event, {})

    assert response["statusCode"] == 401
