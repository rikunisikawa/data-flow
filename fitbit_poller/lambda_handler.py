import json
import logging
import os
from datetime import datetime, timedelta, timezone

import boto3

from fitbit_common.events import build_event, serialize_event
from fitbit_common.http import FitbitApiError, request_json
from fitbit_common.secrets import get_secret_json
from fitbit_common.tokens import get_tokens_table, get_valid_access_token, update_last_polled_at

logger = logging.getLogger()
logger.setLevel(logging.INFO)

BASE_URL = "https://api.fitbit.com/1/user"


def _should_process_user(user_record, shard_id, shard_count, min_interval_seconds):
    if shard_count > 1:
        shard_value = hash(user_record["user_id"]) % shard_count
        if shard_value != shard_id:
            return False

    last_polled_at = int(user_record.get("last_polled_at", 0))
    now_ts = int(datetime.now(timezone.utc).timestamp())
    return now_ts - last_polled_at >= min_interval_seconds


def _fetch_heart_rate(access_token, fitbit_user_id, start_time, end_time):
    date_str = start_time.strftime("%Y-%m-%d")
    start_str = start_time.strftime("%H:%M")
    end_str = end_time.strftime("%H:%M")
    endpoint = f"activities/heart/date/{date_str}/1d/1min/time/{start_str}/{end_str}.json"
    url = f"{BASE_URL}/{fitbit_user_id}/{endpoint}"
    headers = {"Authorization": f"Bearer {access_token}"}
    _, payload, _ = request_json("GET", url, headers=headers)
    return payload


def lambda_handler(event, context):
    table_name = os.environ["TOKENS_TABLE"]
    oauth_secret_arn = os.environ["FITBIT_OAUTH_SECRET_ARN"]
    stream_name = os.environ["FIREHOSE_STREAM_NAME"]

    shard_id = int(os.environ.get("SHARD_ID", "0"))
    shard_count = int(os.environ.get("SHARD_COUNT", "1"))
    lookback_minutes = int(os.environ.get("POLL_LOOKBACK_MINUTES", "10"))
    min_interval_seconds = int(os.environ.get("MIN_POLL_INTERVAL_SECONDS", "300"))

    firehose = boto3.client("firehose")
    table = get_tokens_table(table_name)
    oauth_secret = get_secret_json(oauth_secret_arn)
    client_id = oauth_secret["client_id"]
    client_secret = oauth_secret["client_secret"]

    start_time = datetime.now(timezone.utc) - timedelta(minutes=lookback_minutes)
    end_time = datetime.now(timezone.utc)

    scan_kwargs = {}
    while True:
        response = table.scan(**scan_kwargs)
        for user_record in response.get("Items", []):
            if not _should_process_user(user_record, shard_id, shard_count, min_interval_seconds):
                continue

            user_id = user_record["user_id"]
            fitbit_user_id = user_record["fitbit_user_id"]
            try:
                access_token = get_valid_access_token(table, user_record, client_id, client_secret)
                payload = _fetch_heart_rate(access_token, fitbit_user_id, start_time, end_time)
                event_payload = build_event(
                    event_type="heart_rate_intraday",
                    user_id=user_id,
                    fitbit_user_id=fitbit_user_id,
                    event_time=end_time.isoformat(),
                    payload=payload,
                )
                firehose.put_record(
                    DeliveryStreamName=stream_name,
                    Record={"Data": f"{serialize_event(event_payload)}\n"},
                )
                update_last_polled_at(table, user_id, int(end_time.timestamp()))
            except FitbitApiError as exc:
                logger.warning(json.dumps({"message": "Poller failed", "error": str(exc), "user_id": user_id}))
            except Exception as exc:
                logger.exception(json.dumps({"message": "Poller error", "error": str(exc), "user_id": user_id}))

        last_evaluated_key = response.get("LastEvaluatedKey")
        if not last_evaluated_key:
            break
        scan_kwargs["ExclusiveStartKey"] = last_evaluated_key

    return {"statusCode": 200, "body": "ok"}
