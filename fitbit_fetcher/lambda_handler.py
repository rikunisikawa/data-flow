import json
import logging
import os

import boto3

from fitbit_common.events import build_event, serialize_event
from fitbit_common.http import FitbitApiError, request_json
from fitbit_common.secrets import get_secret_json
from fitbit_common.tokens import get_token_record_by_fitbit_user_id, get_tokens_table, get_valid_access_token

logger = logging.getLogger()
logger.setLevel(logging.INFO)

BASE_URL = "https://api.fitbit.com/1/user"

COLLECTION_ENDPOINTS = {
    "activities": "activities/date/{date}.json",
    "sleep": "sleep/date/{date}.json",
    "body": "body/log/weight/date/{date}.json",
    "foods": "foods/log/date/{date}.json",
    "weight": "body/log/weight/date/{date}.json",
}


def _fetch_collection(access_token, fitbit_user_id, collection_type, date):
    endpoint = COLLECTION_ENDPOINTS.get(collection_type)
    if not endpoint:
        raise ValueError(f"Unsupported collection type: {collection_type}")
    url = f"{BASE_URL}/{fitbit_user_id}/{endpoint.format(date=date)}"
    headers = {"Authorization": f"Bearer {access_token}"}
    _, payload, _ = request_json("GET", url, headers=headers)
    return payload


def lambda_handler(event, context):
    table_name = os.environ["TOKENS_TABLE"]
    oauth_secret_arn = os.environ["FITBIT_OAUTH_SECRET_ARN"]
    stream_name = os.environ["FIREHOSE_STREAM_NAME"]

    firehose = boto3.client("firehose")
    table = get_tokens_table(table_name)
    oauth_secret = get_secret_json(oauth_secret_arn)
    client_id = oauth_secret["client_id"]
    client_secret = oauth_secret["client_secret"]

    batch_item_failures = []
    for record in event.get("Records", []):
        message_id = record.get("messageId")
        try:
            body = json.loads(record.get("body") or "{}")
            fitbit_user_id = body.get("ownerId")
            collection_type = body.get("collectionType")
            date = body.get("date")
            if not (fitbit_user_id and collection_type and date):
                raise ValueError("Missing required fields in webhook payload")

            token_record = get_token_record_by_fitbit_user_id(table, fitbit_user_id)
            if not token_record:
                raise ValueError(f"Token record not found for fitbit_user_id: {fitbit_user_id}")

            access_token = get_valid_access_token(table, token_record, client_id, client_secret)
            payload = _fetch_collection(access_token, fitbit_user_id, collection_type, date)

            event_time = f"{date}T00:00:00Z"
            event_payload = build_event(
                event_type=collection_type,
                user_id=token_record["user_id"],
                fitbit_user_id=fitbit_user_id,
                event_time=event_time,
                payload=payload,
            )

            firehose.put_record(
                DeliveryStreamName=stream_name,
                Record={"Data": f"{serialize_event(event_payload)}\n"},
            )
        except (FitbitApiError, ValueError) as exc:
            logger.warning(json.dumps({"message": "Fetcher failed", "error": str(exc), "message_id": message_id}))
            if message_id:
                batch_item_failures.append({"itemIdentifier": message_id})
        except Exception as exc:
            logger.exception(json.dumps({"message": "Fetcher error", "error": str(exc), "message_id": message_id}))
            if message_id:
                batch_item_failures.append({"itemIdentifier": message_id})

    return {"batchItemFailures": batch_item_failures}
