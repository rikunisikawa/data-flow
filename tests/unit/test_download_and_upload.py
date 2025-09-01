import os
import boto3
import pytest
import requests_mock
from download_and_upload import download_and_upload

def test_handler_success(s3_client, monkeypatch):
    # GIVEN
    # Mock environment variables
    monkeypatch.setenv("DOWNLOAD_URL", "http://test.com/data.txt")
    monkeypatch.setenv("S3_BUCKET_NAME", "test-bucket")
    monkeypatch.setenv("S3_KEY", "test-key.txt")

    # Create mock S3 bucket
    s3_client.create_bucket(Bucket="test-bucket")

    # Mock the request
    url = "http://test.com/data.txt"
    mock_content = b"This is a test file."
    
    with requests_mock.Mocker() as m:
        m.get(url, content=mock_content)

        # WHEN
        result = download_and_upload.handler({}, {})

    # THEN
    assert result["statusCode"] == 200
    
    # Verify file in S3
    s3_object = s3_client.get_object(Bucket="test-bucket", Key="test-key.txt")
    assert s3_object["Body"].read() == mock_content

def test_handler_http_error(monkeypatch):
    # GIVEN
    monkeypatch.setenv("DOWNLOAD_URL", "http://test.com/data.txt")
    monkeypatch.setenv("S3_BUCKET_NAME", "test-bucket")
    monkeypatch.setenv("S3_KEY", "test-key.txt")

    url = "http://test.com/data.txt"
    with requests_mock.Mocker() as m:
        m.get(url, status_code=404)

        # WHEN/THEN
        with pytest.raises(Exception) as e:
            download_and_upload.handler({}, {})
        assert "404 Client Error" in str(e.value)

def test_handler_s3_error(s3_client, monkeypatch):
    # GIVEN
    monkeypatch.setenv("DOWNLOAD_URL", "http://test.com/data.txt")
    monkeypatch.setenv("S3_BUCKET_NAME", "non-existent-bucket")
    monkeypatch.setenv("S3_KEY", "test-key.txt")

    url = "http://test.com/data.txt"
    with requests_mock.Mocker() as m:
        m.get(url, content=b"test")

        # WHEN/THEN
        with pytest.raises(Exception) as e:
            download_and_upload.handler({}, {})
        assert "NoSuchBucket" in str(e.value)
