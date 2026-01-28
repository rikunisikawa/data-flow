import json
import uuid
from datetime import datetime, timezone


def build_event(event_type, user_id, fitbit_user_id, event_time, payload, schema_version="1"):
    if isinstance(payload, (dict, list)):
        payload_value = json.dumps(payload, ensure_ascii=False)
    else:
        payload_value = str(payload)

    event = {
        "event_id": str(uuid.uuid4()),
        "source": "fitbit",
        "user_id": user_id,
        "fitbit_user_id": fitbit_user_id,
        "event_type": event_type,
        "event_time": event_time,
        "ingest_time": datetime.now(timezone.utc).isoformat(),
        "payload": payload_value,
        "schema_version": schema_version,
    }
    return event


def serialize_event(event):
    return json.dumps(event, ensure_ascii=False)
