import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import col, regexp_extract

args = getResolvedOptions(sys.argv, ['JOB_NAME', 'S3_INPUT_PATH', 'S3_OUTPUT_PATH'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# S3からParquetファイルを読み込む
datasource = glueContext.create_dynamic_frame.from_options(
    connection_type="s3",
    connection_options={"paths": [args['S3_INPUT_PATH']]},
    format="parquet",
    transformation_ctx="datasource"
)

# カラム名を定義
column_names = [
    "chest_accel_x", "chest_accel_y", "chest_accel_z",
    "chest_ecg_lead1", "chest_ecg_lead2",
    "left_ankle_accel_x", "left_ankle_accel_y", "left_ankle_accel_z",
    "left_ankle_gyro_x", "left_ankle_gyro_y", "left_ankle_gyro_z",
    "left_ankle_mag_x", "left_ankle_mag_y", "left_ankle_mag_z",
    "right_lower_arm_accel_x", "right_lower_arm_accel_y", "right_lower_arm_accel_z",
    "right_lower_arm_gyro_x", "right_lower_arm_gyro_y", "right_lower_arm_gyro_z",
    "right_lower_arm_mag_x", "right_lower_arm_mag_y", "right_lower_arm_mag_z",
    "activity_label"
]

# 元のDataFrameのカラム数に合わせてカラム名を調整
original_columns = [f"`_{i}`" for i in range(len(column_names))]
df = datasource.toDF()

# カラム名を変更
for old_name, new_name in zip(original_columns, column_names):
    df = df.withColumnRenamed(old_name, new_name)

# ファイル名からuser_idを抽出
df = df.withColumn("user_id", regexp_extract(col("input_file_name"), r"mHealth_subject(\d+)\.log", 1))

# 必要なカラムを選択
selected_columns = [
    "user_id",
    "activity_label",
    "chest_accel_x", "chest_accel_y", "chest_accel_z",
    "left_ankle_accel_x", "left_ankle_accel_y", "left_ankle_accel_z",
    "right_lower_arm_accel_x", "right_lower_arm_accel_y", "right_lower_arm_accel_z"
]

df_selected = df.select(*selected_columns)

# DynamicFrameに変換
dynamic_frame = DynamicFrame.fromDF(df_selected, glueContext, "dynamic_frame")

# データをS3に書き込む
glueContext.write_dynamic_frame.from_options(
    frame=dynamic_frame,
    connection_type="s3",
    connection_options={"path": args['S3_OUTPUT_PATH']},
    format="parquet",
    transformation_ctx="datasink"
)

job.commit()