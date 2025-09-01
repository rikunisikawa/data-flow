import os
import io
import pandas as pd
import pytest
from convert_log_to_parquet import lambda_handler

@pytest.fixture
def mock_env(monkeypatch, s3_bucket):
    monkeypatch.setenv("BUCKET_NAME", s3_bucket)
    return s3_bucket

def test_handler_success(mock_env, s3_client):
    """
    GIVEN a valid log file in the raw S3 prefix
    WHEN the lambda_handler is invoked
    THEN it should convert the log to a partitioned Parquet file in the stage prefix
    """
    bucket_name = mock_env
    # Arrange: Read sample log data and upload to mock S3
    with open("tests/data/mHealth_subject1.log", "rb") as f:
        log_content = f.read()
    s3_client.put_object(Bucket=bucket_name, Key="raw/subject1.log", Body=log_content)
    
    # Act
    result = lambda_handler({}, None)

    # Assert: Check status code and body
    assert result["statusCode"] == 200
    assert "Successfully processed 1" in result["body"]

    # Assert: Check that two parquet files were created for the two activity labels
    expected_keys = [
        f"stage/subject_id=1/activity_label=1/data_1_1.parquet",
        f"stage/subject_id=1/activity_label=2/data_1_2.parquet",
    ]
    
    listed_objects = s3_client.list_objects_v2(Bucket=bucket_name, Prefix="stage/")
    found_keys = [obj['Key'] for obj in listed_objects.get('Contents', [])]
    
    assert len(found_keys) == 2
    assert sorted(found_keys) == sorted(expected_keys)

    # Assert: Check content of one of the parquet files
    obj = s3_client.get_object(Bucket=bucket_name, Key=expected_keys[0])
    df = pd.read_parquet(io.BytesIO(obj['Body'].read()))
    
    assert len(df) == 2 # Two rows with activity_label=1
    assert df['chest_acc_x'].iloc[0] == 1.0
    assert df['chest_acc_x'].iloc[1] == 1.2
    assert (df['activity_label'] == 1).all()

def test_handler_no_bucket_env():
    """
    GIVEN the BUCKET_NAME environment variable is not set
    WHEN the lambda_handler is invoked
    THEN it should return a 500 error
    """
    # Act
    result = lambda_handler({}, None)

    # Assert
    assert result["statusCode"] == 500
    assert "BUCKET_NAME not set" in result["body"]

def test_handler_no_files_to_process(mock_env):
    """
    GIVEN there are no log files in the raw S3 prefix
    WHEN the lambda_handler is invoked
    THEN it should process 0 files and succeed
    """
    # Act
    result = lambda_handler({}, None)

    # Assert
    assert result["statusCode"] == 200
    assert "Successfully processed 0" in result["body"]

def test_handler_filename_no_match(mock_env, s3_client):
    """
    GIVEN a log file with a name that doesn't match the subject_id pattern
    WHEN the lambda_handler is invoked
    THEN it should skip the file and succeed
    """
    bucket_name = mock_env
    s3_client.put_object(Bucket=bucket_name, Key="raw/invalid_filename.log", Body=b"data")
    
    result = lambda_handler({}, None)
    
    assert result["statusCode"] == 200
    assert "Successfully processed 0" in result["body"]