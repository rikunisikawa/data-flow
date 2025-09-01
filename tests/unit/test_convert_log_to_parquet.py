import os
import io
import pandas as pd
import pytest
from convert_log_to_parquet import convert_log_to_parquet

@pytest.fixture
def mock_env(monkeypatch, s3_bucket):
    monkeypatch.setenv("BUCKET_NAME", s3_bucket)

def test_handler_success(mock_env, s3_client, s3_bucket):
    """
    GIVEN a valid log file in the raw S3 prefix
    WHEN the lambda_handler is invoked
    THEN it should convert the log to a partitioned Parquet file in the stage prefix
    """
    # Arrange: Create a sample log file and upload to mock S3
    log_content = (
        "1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0 14.0 "
        "15.0 16.0 17.0 18.0 19.0 20.0 21.0 22.0 23.0 1\n"
        "1.1 2.1 3.1 4.1 5.1 6.1 7.1 8.1 9.1 10.1 11.1 12.1 13.1 14.1 "
        "15.1 16.1 17.1 18.1 19.1 20.1 21.1 22.1 23.1 2\n"
        "1.2 2.2 3.2 4.2 5.2 6.2 7.2 8.2 9.2 10.2 11.2 12.2 13.2 14.2 "
        "15.2 16.2 17.2 18.2 19.2 20.2 21.2 22.2 23.2 1\n"
    )
    s3_client.put_object(Bucket=s3_bucket, Key="raw/mHealth_subject1.log", Body=log_content)
    
    # Act
    result = convert_log_to_parquet.lambda_handler({}, None)

    # Assert: Check status code and body
    assert result["statusCode"] == 200
    assert "Successfully processed 1 log files" in result["body"]

    # Assert: Check that two parquet files were created for the two activity labels
    expected_keys = [
        f"stage/subject_id=1/activity_label=1/data_1_1.parquet",
        f"stage/subject_id=1/activity_label=2/data_1_2.parquet",
    ]
    
    listed_objects = s3_client.list_objects_v2(Bucket=s3_bucket, Prefix="stage/")
    found_keys = [obj['Key'] for obj in listed_objects.get('Contents', [])]
    
    assert len(found_keys) == 2
    assert sorted(found_keys) == sorted(expected_keys)

    # Assert: Check content of one of the parquet files
    obj = s3_client.get_object(Bucket=s3_bucket, Key=expected_keys[0])
    df = pd.read_parquet(io.BytesIO(obj['Body'].read()))
    
    assert len(df) == 2 # Two rows with activity_label=1
    assert df['chest_acc_x'].iloc[0] == 1.0
    assert df['chest_acc_x'].iloc[1] == 1.2
    assert (df['activity_label'] == 1).all()

def test_handler_no_bucket_env(s3_client, s3_bucket):
    """
    GIVEN the BUCKET_NAME environment variable is not set
    WHEN the lambda_handler is invoked
    THEN it should return a 500 error
    """
    # Act
    result = convert_log_to_parquet.lambda_handler({}, None)

    # Assert
    assert result["statusCode"] == 500
    assert "BUCKET_NAME not set" in result["body"]

def test_handler_no_files_to_process(mock_env, s3_client, s3_bucket):
    """
    GIVEN there are no log files in the raw S3 prefix
    WHEN the lambda_handler is invoked
    THEN it should process 0 files and succeed
    """
    # Act
    result = convert_log_to_parquet.lambda_handler({}, None)

    # Assert
    assert result["statusCode"] == 200
    assert "Successfully processed 0 log files" in result["body"]
