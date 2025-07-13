import os
import boto3
import pandas as pd
import pyarrow
import pyarrow.parquet as pq
import io

BUCKET_NAME = os.environ.get('BUCKET_NAME')
S3_CLIENT = boto3.client('s3')

def lambda_handler(event, context):
    """
    S3に保存されたlogファイルをParquet形式に変換し、S3に保存するLambda関数
    Step Functions経由で実行される
    """
    try:
        # S3 raw/フォルダ内の全ての.logファイルを取得
        response = S3_CLIENT.list_objects_v2(Bucket=BUCKET_NAME, Prefix='raw/')
        
        converted_files = []
        
        if 'Contents' in response:
            for obj in response['Contents']:
                key = obj['Key']
                if key.endswith('.log'):
                    # logファイルをダウンロード
                    log_file = S3_CLIENT.get_object(Bucket=BUCKET_NAME, Key=key)
                    log_content = log_file['Body'].read()

                    # pandasでlogファイルを読み込み
                    df = pd.read_csv(io.BytesIO(log_content), sep='\t', header=None)

                    # Parquet形式に変換
                    table = pyarrow.Table.from_pandas(df)
                    parquet_buffer = pyarrow.BufferOutputStream()
                    pq.write_table(table, parquet_buffer)

                    # ParquetファイルをS3にアップロード
                    parquet_key = key.replace('raw/', 'stage/').replace('.log', '.parquet')
                    S3_CLIENT.put_object(Bucket=BUCKET_NAME, Key=parquet_key, Body=parquet_buffer.getvalue().to_pybytes())
                    
                    converted_files.append(parquet_key)
                    print(f"Uploaded {parquet_key} to s3://{BUCKET_NAME}/{parquet_key}")

        return {
            'statusCode': 200,
            'body': f'Successfully converted {len(converted_files)} log files to Parquet',
            'convertedFiles': converted_files
        }
    except Exception as e:
        print(f"Error: {e}")
        return {
            'statusCode': 500,
            'body': f'Error: {e}'
        }
