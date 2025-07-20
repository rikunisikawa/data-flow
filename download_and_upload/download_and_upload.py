import boto3
import os
import zipfile
import logging

# Logger setup
logger = logging.getLogger()
logger.setLevel(logging.INFO)
if not logger.handlers:
    log_handler = logging.FileHandler('logs/download_and_upload.log')
    log_formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    log_handler.setFormatter(log_formatter)
    logger.addHandler(log_handler)

def get_api():
    from kaggle.api.kaggle_api_extended import KaggleApi
    return KaggleApi()

def get_s3_client():
    return boto3.client('s3')

def lambda_handler(event, context):
    kaggle_username = os.environ.get('KAGGLE_USERNAME')
    kaggle_key = os.environ.get('KAGGLE_KEY')
    bucket_name = os.environ.get('BUCKET_NAME')

    if not all([kaggle_username, kaggle_key, bucket_name]):
        logger.error("Environment variables KAGGLE_USERNAME, KAGGLE_KEY, or BUCKET_NAME not set")
        return {
            'statusCode': 500,
            'body': 'Required environment variables not set'
        }

    api = get_api()
    api.set_config_value('username', kaggle_username)
    api.set_config_value('key', kaggle_key)
    api.authenticate()

    dataset = 'nirmalsankalana/mhealth-dataset-data-set'
    download_dir = '/tmp'
    extract_path = '/tmp/mhealth'

    try:
        logger.info(f"Downloading dataset: {dataset}")
        api.dataset_download_files(dataset, path=download_dir, unzip=False)

        downloaded_files = os.listdir(download_dir)
        zip_file_name = next((f for f in downloaded_files if f.endswith('.zip')), None)
        if not zip_file_name:
            logger.error("Could not find the downloaded zip file.")
            raise FileNotFoundError("Could not find the downloaded zip file.")
        
        download_path = os.path.join(download_dir, zip_file_name)
        logger.info(f"Downloaded zip file: {download_path}")

        with zipfile.ZipFile(download_path, 'r') as zip_ref:
            zip_ref.extractall(extract_path)
        logger.info(f"Extracted zip file to: {extract_path}")

        s3 = get_s3_client()
        
        uploaded_files = []
        for root, dirs, files in os.walk(extract_path):
            for file in files:
                if file.endswith(".log"):
                    file_path = os.path.join(root, file)
                    s3_key = f'raw/{file}'
                    logger.info(f"Uploading {file_path} to s3://{bucket_name}/{s3_key}")
                    s3.upload_file(file_path, bucket_name, s3_key)
                    uploaded_files.append(s3_key)

        logger.info(f"Successfully uploaded {len(uploaded_files)} log files to S3")
        return {
            'statusCode': 200,
            'body': f'Successfully uploaded {len(uploaded_files)} log files to S3',
            'uploaded_files': uploaded_files
        }
    except Exception as e:
        logger.error(f"Error: {e}", exc_info=True)
        return {
            'statusCode': 500,
            'body': f'Error: {e}'
        }
