import os
import boto3
import pandas as pd
import pyarrow
import pyarrow.parquet as pq

BUCKET_NAME = os.environ.get('BUCKET_NAME')
S3_CLIENT = boto3.client('s3')

def lambda_handler(event, context):
    """
    S3に保存されたCSVファイルをParquet形式に変換し、S3に保存するLambda関数
    """
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        if key.endswith('.csv'):
            try:
                # CSVファイルをダウンロード
                csv_file = S3_CLIENT.get_object(Bucket=bucket, Key=key)
                csv_content = csv_file['Body'].read()

                # pandasでCSVファイルを読み込み
                df = pd.read_csv(csv_content)

                # Parquet形式に変換
                table = pyarrow.Table.from_pandas(df)
                parquet_buffer = pyarrow.BufferOutputStream()
                pq.write_table(table, parquet_buffer)

                # ParquetファイルをS3にアップロード
                parquet_key = key.replace('raw/', 'stage/').replace('.csv', '.parquet')
                S3_CLIENT.put_object(Bucket=BUCKET_NAME, Key=parquet_key, Body=parquet_buffer.getvalue().to_pybytes())
                print(f"Uploaded {parquet_key} to s3://{BUCKET_NAME}/{parquet_key}")

                return {
                    'statusCode': 200,
                    'body': 'Successfully converted CSV to Parquet and uploaded to S3'
                }
            except Exception as e:
                print(f"Error: {e}")
                return {
                    'statusCode': 500,
                    'body': f'Error: {e}'
                }
