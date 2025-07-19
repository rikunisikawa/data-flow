import boto3
import os
import zipfile
from kaggle.api.kaggle_api_extended import KaggleApi

def lambda_handler(event, context):
    kaggle_username = os.environ.get('KAGGLE_USERNAME')
    kaggle_key = os.environ.get('KAGGLE_KEY')

    if not kaggle_username or not kaggle_key:
        print("KAGGLE_USERNAME or KAGGLE_KEY not set")
        return {
            'statusCode': 500,
            'body': 'KAGGLE_USERNAME or KAGGLE_KEY not set'
        }

    api = KaggleApi()
    api.set_config_value('username', kaggle_username)
    api.set_config_value('key', kaggle_key)
    api.authenticate()

    dataset = 'nirmalsankalana/mhealth-dataset-data-set'
    download_dir = '/tmp'
    extract_path = '/tmp/mhealth'

    try:
        # Download the dataset to the /tmp directory
        api.dataset_download_files(dataset, path=download_dir, unzip=False)

        # Find the downloaded zip file
        downloaded_files = os.listdir(download_dir)
        zip_file_name = next((f for f in downloaded_files if f.endswith('.zip')), None)
        if not zip_file_name:
            raise FileNotFoundError("Could not find the downloaded zip file.")
        
        download_path = os.path.join(download_dir, zip_file_name)

        with zipfile.ZipFile(download_path, 'r') as zip_ref:
            zip_ref.extractall(extract_path)

        s3 = boto3.client('s3')
        bucket = os.environ['BUCKET_NAME']

        uploaded_files = []
        for root, dirs, files in os.walk(extract_path):
            for file in files:
                if file.endswith(".log"):
                    file_path = os.path.join(root, file)
                    s3_key = f'raw/{file}'
                    s3.upload_file(file_path, bucket, s3_key)
                    uploaded_files.append(s3_key)

        return {
            'statusCode': 200,
            'body': f'Successfully uploaded {len(uploaded_files)} log files to S3',
            'uploaded_files': uploaded_files
        }
    except Exception as e:
        print(f"Error: {e}")
        return {
            'statusCode': 500,
            'body': f'Error: {e}'
        }