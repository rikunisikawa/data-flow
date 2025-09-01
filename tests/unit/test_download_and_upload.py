import os
from unittest.mock import MagicMock, patch
import pytest
from download_and_upload import download_and_upload

@pytest.fixture
def mock_env(monkeypatch):
    monkeypatch.setenv("KAGGLE_USERNAME", "testuser")
    monkeypatch.setenv("KAGGLE_KEY", "testkey")
    monkeypatch.setenv("BUCKET_NAME", "test-bucket")

@patch("download_and_upload.download_and_upload.get_api")
@patch("zipfile.ZipFile")
@patch("os.walk")
def test_handler_success(mock_walk, mock_zipfile, mock_get_api, mock_env, s3_client, s3_bucket):
    """
    GIVEN a valid environment and mocked external services
    WHEN the lambda_handler is invoked
    THEN it should download, extract, and upload the target log file to S3
    """
    # Arrange: Mock Kaggle API
    mock_api_instance = MagicMock()
    mock_get_api.return_value = mock_api_instance

    # Arrange: Mock os.listdir to find the zip file
    with patch("os.listdir", return_value=["mhealth-dataset-data-set.zip"]):
        # Arrange: Mock os.walk to find the extracted log file
        mock_walk.return_value = [
            ("/tmp/mhealth/some_dir", [], ["mHealth_subject1.log"]),
        ]
        
        # Arrange: Mock file content
        log_content = "log data"
        mock_open = patch("builtins.open", MagicMock())
        mock_open.read.return_value = log_content

        # Act
        result = download_and_upload.lambda_handler({}, None)

    # Assert
    assert result["statusCode"] == 200
    assert "Successfully uploaded 1 log files to S3" in result["body"]
    
    mock_api_instance.dataset_download_files.assert_called_once_with(
        'nirmalsankalana/mhealth-dataset-data-set', path='/tmp', unzip=False
    )
    mock_zipfile.assert_called_with('/tmp/mhealth-dataset-data-set.zip', 'r')
    
    # Assert S3 upload
    response = s3_client.get_object(Bucket=s3_bucket, Key="raw/mHealth_subject1.log")
    assert response is not None # upload_file is mocked by moto, this confirms it was called

def test_handler_missing_env_vars():
    """
    GIVEN a missing environment variable
    WHEN the lambda_handler is invoked
    THEN it should return a 500 error
    """
    # Act
    result = download_and_upload.lambda_handler({}, None)

    # Assert
    assert result["statusCode"] == 500
    assert "Required environment variables not set" in result["body"]
