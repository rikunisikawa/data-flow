import os
import pytest
from unittest.mock import patch, MagicMock, mock_open
import zipfile
import sys

# Add the lambda function path to the sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../download_and_upload')))

import download_and_upload

@pytest.fixture
def mock_env(monkeypatch):
    monkeypatch.setenv('KAGGLE_USERNAME', 'testuser')
    monkeypatch.setenv('KAGGLE_KEY', 'testkey')
    monkeypatch.setenv('BUCKET_NAME', 'test-bucket')

@pytest.fixture
def mock_kaggle_api():
    with patch('download_and_upload.get_api') as mock_get_api:
        mock_api = MagicMock()
        mock_get_api.return_value = mock_api
        yield mock_api

@pytest.fixture
def mock_s3_client():
    with patch('download_and_upload.get_s3_client') as mock_get_s3:
        mock_s3 = MagicMock()
        mock_get_s3.return_value = mock_s3
        yield mock_s3

def test_lambda_handler_success(mock_env, mock_kaggle_api, mock_s3_client, monkeypatch):
    # Use monkeypatch to control the /tmp directory used by the lambda
    tmp_path = '/tmp'
    extract_path = '/tmp/mhealth'
    zip_file_name = 'mhealth-dataset-data-set.zip'
    zip_path = os.path.join(tmp_path, zip_file_name)
    log_file_name = 'mHealth_subject1.log'
    log_file_path = os.path.join(extract_path, log_file_name)

    # Mock os level functions
    monkeypatch.setattr(os, 'listdir', lambda path: [zip_file_name] if path == tmp_path else [])
    
    # Mock zipfile.ZipFile to simulate extraction
    mock_zip = MagicMock()
    mock_zip.extractall.return_value = None
    # We need to mock the context manager part of ZipFile
    mock_zip_context = MagicMock()
    mock_zip_context.__enter__.return_value = mock_zip
    mock_zip_context.__exit__.return_value = None
    monkeypatch.setattr(zipfile, 'ZipFile', lambda path, mode: mock_zip_context)

    monkeypatch.setattr(os, 'walk', lambda path: [(extract_path, [], [log_file_name])])

    # Run the handler
    result = download_and_upload.lambda_handler({}, {})

    # Assertions
    mock_kaggle_api.dataset_download_files.assert_called_once_with(
        'nirmalsankalana/mhealth-dataset-data-set', path=tmp_path, unzip=False
    )
    
    mock_s3_client.upload_file.assert_called_once_with(
        log_file_path, 'test-bucket', f'raw/{log_file_name}'
    )
    
    assert result['statusCode'] == 200
    assert 'Successfully uploaded 1 log files to S3' in result['body']
    assert result['uploaded_files'] == [f'raw/{log_file_name}']

def test_lambda_handler_no_zip_found(mock_env, mock_kaggle_api, monkeypatch):
    tmp_path = '/tmp'
    monkeypatch.setattr(os, 'listdir', lambda path: ['not_a_zip.txt'])
    
    result = download_and_upload.lambda_handler({}, {})

    assert result['statusCode'] == 500
    assert 'Could not find the downloaded zip file.' in result['body']

def test_lambda_handler_no_env_vars():
    result = download_and_upload.lambda_handler({}, {})
    assert result['statusCode'] == 500
    assert 'Required environment variables not set' in result['body']

def test_lambda_handler_exception(mock_env, mock_kaggle_api):
    mock_kaggle_api.dataset_download_files.side_effect = Exception("Kaggle API Error")

    result = download_and_upload.lambda_handler({}, {})

    assert result['statusCode'] == 500
    assert 'Error: Kaggle API Error' in result['body']
