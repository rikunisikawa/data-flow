import os
import boto3
import pandas as pd

import io
import logging

# Logger setup
logger = logging.getLogger()
logger.setLevel(logging.INFO)
if not logger.handlers:
    log_handler = logging.FileHandler('logs/convert_log_to_parquet.log')
    log_formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    log_handler.setFormatter(log_formatter)
    logger.addHandler(log_handler)

def get_s3_client():
    return boto3.client('s3')

# Define column names based on the dataset description
COLUMN_NAMES = [
    'chest_acc_x', 'chest_acc_y', 'chest_acc_z',
    'chest_ecg_1', 'chest_ecg_2',
    'left_ankle_acc_x', 'left_ankle_acc_y', 'left_ankle_acc_z',
    'left_ankle_gyro_x', 'left_ankle_gyro_y', 'left_ankle_gyro_z',
    'left_ankle_mag_x', 'left_ankle_mag_y', 'left_ankle_mag_z',
    'right_lower_arm_acc_x', 'right_lower_arm_acc_y', 'right_lower_arm_acc_z',
    'right_lower_arm_gyro_x', 'right_lower_arm_gyro_y', 'right_lower_arm_gyro_z',
    'right_lower_arm_mag_x', 'right_lower_arm_mag_y', 'right_lower_arm_mag_z',
    'activity_label'
]

def lambda_handler(event, context):
    """
    Converts log files from S3 to Parquet format and saves them back to S3.
    Triggered via Step Functions.
    """
    bucket_name = os.environ.get('BUCKET_NAME')
    if not bucket_name:
        logger.error("Environment variable BUCKET_NAME not set")
        return {
            'statusCode': 500,
            'body': 'Environment variable BUCKET_NAME not set'
        }

    s3_client = get_s3_client()
    
    try:
        logger.info(f"Listing objects in s3://{bucket_name}/raw/")
        response = s3_client.list_objects_v2(Bucket=bucket_name, Prefix='raw/')
        
        converted_files = []
        
        if 'Contents' in response:
            for obj in response['Contents']:
                key = obj['Key']
                if key.endswith('.log'):
                    logger.info(f"Processing file: {key}")
                    
                    log_file = s3_client.get_object(Bucket=bucket_name, Key=key)
                    log_content = log_file['Body'].read()

                    # Use StringIO to handle text data, and specify separator and header
                    df = pd.read_csv(io.StringIO(log_content.decode('utf-8')), sep=r'\s+', header=None)

                    # Check if the number of parsed columns matches the expected number
                    if len(df.columns) != len(COLUMN_NAMES):
                        logger.warning(
                            f"Skipping file {key}: Column count mismatch. "
                            f"Expected {len(COLUMN_NAMES)}, but parsed {len(df.columns)}. "
                            "Check for delimiters in the source file."
                        )
                        continue

                    df.columns = COLUMN_NAMES

                    parquet_buffer = io.BytesIO()
                    df.to_parquet(parquet_buffer, engine='fastparquet', index=False)

                    parquet_key = key.replace('raw/', 'stage/').replace('.log', '.parquet')
                    s3_client.put_object(Bucket=bucket_name, Key=parquet_key, Body=parquet_buffer.getvalue())
                    
                    converted_files.append(parquet_key)
                    logger.info(f"Successfully converted and uploaded {parquet_key}")

        logger.info(f"Successfully converted {len(converted_files)} files.")
        return {
            'statusCode': 200,
            'body': f'Successfully converted {len(converted_files)} log files to Parquet',
            'convertedFiles': converted_files
        }
    except Exception as e:
        logger.error(f"Error processing files: {e}", exc_info=True)
        return {
            'statusCode': 500,
            'body': f'Error: {e}'
        }