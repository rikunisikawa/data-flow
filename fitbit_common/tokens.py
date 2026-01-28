import base64
from datetime import datetime, timezone

import boto3
from boto3.dynamodb.conditions import Key

from fitbit_common.http import request_json

FITBIT_TOKEN_URL = "https://api.fitbit.com/oauth2/token"


def get_tokens_table(table_name):
    return boto3.resource("dynamodb").Table(table_name)


def get_token_record(table, user_id):
    response = table.get_item(Key={"user_id": user_id})
    return response.get("Item")


def get_token_record_by_fitbit_user_id(table, fitbit_user_id):
    response = table.query(
        IndexName="fitbit_user_id_index",
        KeyConditionExpression=Key("fitbit_user_id").eq(fitbit_user_id),
        Limit=1,
    )
    items = response.get("Items", [])
    return items[0] if items else None


def refresh_access_token(token_record, client_id, client_secret):
    auth_bytes = f"{client_id}:{client_secret}".encode("utf-8")
    auth_header = base64.b64encode(auth_bytes).decode("utf-8")
    headers = {
        "Authorization": f"Basic {auth_header}",
        "Content-Type": "application/x-www-form-urlencoded",
    }
    data = {
        "grant_type": "refresh_token",
        "refresh_token": token_record["refresh_token"],
    }
    _, payload, _ = request_json("POST", FITBIT_TOKEN_URL, headers=headers, data=data)
    now = datetime.now(timezone.utc).timestamp()
    expires_in = payload.get("expires_in", 0)
    return {
        "access_token": payload["access_token"],
        "refresh_token": payload.get("refresh_token", token_record["refresh_token"]),
        "expires_at": int(now + expires_in),
        "scopes": payload.get("scope", token_record.get("scopes", "")),
    }


def get_valid_access_token(table, token_record, client_id, client_secret, refresh_margin_seconds=300):
    if not token_record:
        raise ValueError("Token record not found")

    expires_at = int(token_record.get("expires_at", 0))
    now = int(datetime.now(timezone.utc).timestamp())
    if expires_at - refresh_margin_seconds <= now:
        refreshed = refresh_access_token(token_record, client_id, client_secret)
        update_expression = "SET access_token = :access_token, refresh_token = :refresh_token, expires_at = :expires_at, scopes = :scopes"
        table.update_item(
            Key={"user_id": token_record["user_id"]},
            UpdateExpression=update_expression,
            ExpressionAttributeValues={
                ":access_token": refreshed["access_token"],
                ":refresh_token": refreshed["refresh_token"],
                ":expires_at": refreshed["expires_at"],
                ":scopes": refreshed["scopes"],
            },
        )
        token_record.update(refreshed)
    return token_record["access_token"]


def update_last_polled_at(table, user_id, timestamp):
    table.update_item(
        Key={"user_id": user_id},
        UpdateExpression="SET last_polled_at = :last_polled_at",
        ExpressionAttributeValues={":last_polled_at": timestamp},
    )
