import os
import boto3
import pandas as pd
import io
import logging
import re

# Logger setup
logger = logging.getLogger()
logger.setLevel(logging.INFO)
if not logger.handlers:
    # stdout handler for Lambda
    stream_handler = logging.StreamHandler()
    log_formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    stream_handler.setFormatter(log_formatter)
    logger.addHandler(stream_handler)

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
    Converts log files from S3 to a partitioned Parquet dataset in S3.
    Partitions by subject_id and activity_label.
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
        
        processed_files_count = 0
        
        if 'Contents' in response:
            for obj in response['Contents']:
                key = obj['Key']
                if key.endswith('.log'):
                    logger.info(f"Processing file: {key}")

                    # Extract subject_id from filename
                    match = re.search(r'subject(\d+)\.log', key)
                    if not match:
                        logger.warning(f"Could not extract subject_id from {key}. Skipping.")
                        continue
                    subject_id = int(match.group(1))

                    log_object = s3_client.get_object(Bucket=bucket_name, Key=key)
                    log_content = log_object['Body'].read()

                    df = pd.read_csv(io.StringIO(log_content.decode('utf-8')), sep=r'\s+', header=None)

                    if len(df.columns) != len(COLUMN_NAMES):
                        logger.warning(
                            f"Skipping file {key}: Column count mismatch. "
                            f"Expected {len(COLUMN_NAMES)}, but parsed {len(df.columns)}."
                        )
                        continue
                    
                    df.columns = COLUMN_NAMES

                    # Partition by activity_label and write to S3
                    for activity_label, group_df in df.groupby('activity_label'):
                        if activity_label == 0: # Skip null class
                            continue

                        partition_key = (
                            f"stage/subject_id={subject_id}/"
                            f"activity_label={activity_label}/"
                            f"data_{subject_id}_{activity_label}.parquet"
                        )
                        
                        parquet_buffer = io.BytesIO()
                        # Use fastparquet engine, which is already in requirements.txt
                        group_df.to_parquet(parquet_buffer, engine='fastparquet', index=False)
                        
                        s3_client.put_object(
                            Bucket=bucket_name,
                            Key=partition_key,
                            Body=parquet_buffer.getvalue()
                        )
                        logger.info(f"Wrote partition to {partition_key}")

                    processed_files_count += 1
                    logger.info(f"Successfully processed {key}")

        logger.info(f"Successfully processed {processed_files_count} files.")
        return {
            'statusCode': 200,
            'body': f'Successfully processed {processed_files_count} log files into partitioned Parquet dataset.'
        }
    except Exception as e:
        logger.error(f"Error processing files: {e}", exc_info=True)
        return {
            'statusCode': 500,
            'body': f'Error: {e}'
        }
