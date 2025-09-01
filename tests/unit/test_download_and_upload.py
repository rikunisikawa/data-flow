import os
import zipfile
from unittest.mock import MagicMock
import pytest
from download_and_upload import lambda_handler

@pytest.fixture
def mock_env(monkeypatch, s3_bucket):
    monkeypatch.setenv("KAGGLE_USERNAME", "testuser")
    monkeypatch.setenv("KAGGLE_KEY", "testkey")
    monkeypatch.setenv("BUCKET_NAME", s3_bucket)
    # Set tmp to a specific test directory to avoid clutter
    monkeypatch.setenv("TMPDIR", "./tests/tmp")
    os.makedirs("./tests/tmp/.kaggle", exist_ok=True)
    yield s3_bucket
    # Teardown
    if os.path.exists("./tests/tmp"):
        import shutil
        shutil.rmtree("./tests/tmp")


@pytest.fixture
def mock_kaggle_api(mocker):
    """Mocks the Kaggle API client."""
    mock_api_instance = MagicMock()
    mock_api_class = mocker.patch("download_and_upload.get_api")
    mock_api_class.return_value = mock_api_instance
    
    def create_zip_file(*args, **kwargs):
        """Create a dummy zip file when download is called."""
        zip_path = os.path.join(kwargs["path"], "mhealth-dataset-data-set.zip")
        log_filename = "mHealth_subject1.log"
        with zipfile.ZipFile(zip_path, 'w') as zf:
            zf.writestr(f"mhealth/{log_filename}", "log data")
    
    mock_api_instance.dataset_download_files.side_effect = create_zip_file
    return mock_api_instance

def test_handler_success(mock_env, mock_kaggle_api, s3_client):
    """
    GIVEN a valid environment and a mocked Kaggle API
    WHEN the lambda_handler is invoked
    THEN it should download, extract, and upload the target log file to S3
    """
    bucket_name = mock_env
    
    # Act
    result = lambda_handler({}, None)

    # Assert: Check status code and successful body
    assert result["statusCode"] == 200
    assert "Successfully uploaded 1 log files to S3" in result["body"]
    assert result["uploaded_files"] == ["raw/mHealth_subject1.log"]

    # Assert: Kaggle API was called correctly
    mock_kaggle_api.dataset_download_files.assert_called_once_with(
        'nirmalsankalana/mhealth-dataset-data-set', path='/tmp', unzip=False
    )
    
    # Assert: File was uploaded to S3 correctly
    response = s3_client.get_object(Bucket=bucket_name, Key="raw/mHealth_subject1.log")
    assert response["Body"].read().decode("utf-8") == "log data"

def test_handler_missing_env_vars():
    """
    GIVEN a missing environment variable
    WHEN the lambda_handler is invoked
    THEN it should return a 500 error
    """
    # Act
    result = lambda_handler({}, None)

    # Assert
    assert result["statusCode"] == 500
    assert "Required environment variables not set" in result["body"]

def test_handler_kaggle_download_fails(mock_env, mock_kaggle_api):
    """
    GIVEN the Kaggle API download fails
    WHEN the lambda_handler is invoked
    THEN it should return a 500 error
    """
    # Arrange
    mock_kaggle_api.dataset_download_files.side_effect = Exception("Kaggle API Error")

    # Act
    result = lambda_handler({}, None)

    # Assert
    assert result["statusCode"] == 500
    assert "Error: Kaggle API Error" in result["body"]