import os
import sys

import boto3
from moto import mock_dynamodb

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from fitbit_common.events import build_event
from fitbit_common.tokens import get_token_record_by_fitbit_user_id, get_tokens_table

os.environ.setdefault("AWS_DEFAULT_REGION", "us-east-1")


@mock_dynamodb
def test_get_token_record_by_fitbit_user_id():
    dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
    table = dynamodb.create_table(
        TableName="fitbit_tokens",
        KeySchema=[{"AttributeName": "user_id", "KeyType": "HASH"}],
        AttributeDefinitions=[
            {"AttributeName": "user_id", "AttributeType": "S"},
            {"AttributeName": "fitbit_user_id", "AttributeType": "S"},
        ],
        GlobalSecondaryIndexes=[
            {
                "IndexName": "fitbit_user_id_index",
                "KeySchema": [{"AttributeName": "fitbit_user_id", "KeyType": "HASH"}],
                "Projection": {"ProjectionType": "ALL"},
            }
        ],
        BillingMode="PAY_PER_REQUEST",
    )

    table.put_item(
        Item={
            "user_id": "user-1",
            "fitbit_user_id": "fitbit-1",
            "access_token": "token",
            "refresh_token": "refresh",
        }
    )

    tokens_table = get_tokens_table("fitbit_tokens")
    record = get_token_record_by_fitbit_user_id(tokens_table, "fitbit-1")
    assert record["user_id"] == "user-1"


def test_build_event():
    event = build_event(
        event_type="sleep",
        user_id="user-1",
        fitbit_user_id="fitbit-1",
        event_time="2024-01-01T00:00:00Z",
        payload={"foo": "bar"},
    )

    assert event["source"] == "fitbit"
    assert event["event_type"] == "sleep"
    assert "\"foo\"" in event["payload"]
