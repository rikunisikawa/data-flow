import json
import os
import pandas as pd
import pyarrow.parquet as pq
import pytest
from convert_log_to_parquet import convert_log_to_parquet

@pytest.fixture
def s3_setup(s3_client):
    s3_client.create_bucket(Bucket="test-input-bucket")
    s3_client.create_bucket(Bucket="test-output-bucket")
    
    # Upload a sample log file
    sample_data = [{"id": 1, "data": "test"}]
    s3_client.put_object(
        Bucket="test-input-bucket",
        Key="logs/sample.json",
        Body=json.dumps(sample_data),
    )

def test_handler_success(s3_client, s3_setup, monkeypatch):
    # GIVEN
    monkeypatch.setenv("OUTPUT_S3_BUCKET_NAME", "test-output-bucket")
    
    # Mock S3 event
    s3_event = {
        "Records": [
            {
                "s3": {
                    "bucket": {"name": "test-input-bucket"},
                    "object": {"key": "logs/sample.json"},
                }
            }
        ]
    }

    # WHEN
    result = convert_log_to_parquet.handler(s3_event, {})

    # THEN
    assert result["statusCode"] == 200
    
    # Verify the output file
    output_key = "format=parquet/logs/sample.parquet"
    response = s3_client.get_object(Bucket="test-output-bucket", Key=output_key)
    
    # Read parquet file from S3 and verify content
    table = pq.read_table(response['Body'])
    df = table.to_pandas()
    
    assert len(df) == 1
    assert df.iloc[0]['id'] == 1
    assert df.iloc[0]['data'] == "test"

def test_handler_no_records(caplog):
    # GIVEN
    empty_event = {"Records": []}

    # WHEN
    result = convert_log_to_parquet.handler(empty_event, {})

    # THEN
    assert result["statusCode"] == 200
    assert "No records found in the event" in caplog.text

def test_handler_s3_error(s3_client, monkeypatch):
    # GIVEN
    monkeypatch.setenv("OUTPUT_S3_BUCKET_NAME", "test-output-bucket")
    
    s3_event = {
        "Records": [
            {
                "s3": {
                    "bucket": {"name": "non-existent-bucket"},
                    "object": {"key": "logs/sample.json"},
                }
            }
        ]
    }

    # WHEN/THEN
    with pytest.raises(Exception) as e:
        convert_log_to_parquet.handler(s3_event, {})
    assert "NoSuchBucket" in str(e.value)
