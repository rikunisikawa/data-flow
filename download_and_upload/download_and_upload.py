import boto3
import os
import boto3
import os
import zipfile
from kaggle.api.kaggle_api_extended import KaggleApi

def lambda_handler(event, context):
    # 環境変数からKAGGLE_USERNAMEとKAGGLE_KEYを取得
    kaggle_username = os.environ.get('KAGGLE_USERNAME')
    kaggle_key = os.environ.get('KAGGLE_KEY')

    if not kaggle_username or not kaggle_key:
        print("KAGGLE_USERNAMEまたはKAGGLE_KEYが設定されていません")
        return {
            'statusCode': 500,
            'body': 'KAGGLE_USERNAMEまたはKAGGLE_KEYが設定されていません'
        }

    # kaggle.jsonは環境変数またはSecrets Managerから取得して配置済み想定
    api = KaggleApi()
    api.set_config_value('username', kaggle_username)
    api.set_config_value('key', kaggle_key)
    api.authenticate()

    dataset = 'nirmalsankalana/mhealth-dataset-data-set'
    download_path = '/tmp/mhealth.zip'
    extract_path = '/tmp/mhealth'

    try:
        api.dataset_download_files(dataset, path='/tmp', unzip=False)

        with zipfile.ZipFile(download_path, 'r') as zip_ref:
            zip_ref.extractall(extract_path)

        s3 = boto3.client('s3')
        bucket = os.environ['BUCKET_NAME']

        for root, dirs, files in os.walk(extract_path):
            for file in files:
                file_path = os.path.join(root, file)
                s3_key = f'raw/{file}'
                s3.upload_file(file_path, bucket, s3_key)

        return {
            'statusCode': 200,
            'body': 'Successfully downloaded and uploaded data to S3'
        }
    except Exception as e:
        print(f"Error: {e}")
        return {
            'statusCode': 500,
            'body': f'Error: {e}'
        }
