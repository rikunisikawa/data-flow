CREATE DATABASE IF NOT EXISTS stage_mhealth;

CREATE EXTERNAL TABLE stage_mhealth.raw_activities (
  chest_acc_x double,
  chest_acc_y double,
  chest_acc_z double,
  chest_ecg_1 double,
  chest_ecg_2 double,
  left_ankle_acc_x double,
  left_ankle_acc_y double,
  left_ankle_acc_z double,
  left_ankle_gyro_x double,
  left_ankle_gyro_y double,
  left_ankle_gyro_z double,
  left_ankle_mag_x double,
  left_ankle_mag_y double,
  left_ankle_mag_z double,
  right_lower_arm_acc_x double,
  right_lower_arm_acc_y double,
  right_lower_arm_acc_z double,
  right_lower_arm_gyro_x double,
  right_lower_arm_gyro_y double,
  right_lower_arm_gyro_z double,
  right_lower_arm_mag_x double,
  right_lower_arm_mag_y double,
  right_lower_arm_mag_z double,
  activity_label bigint
)
STORED AS PARQUET
LOCATION 's3://aws-data-platform-20250607/stage/';
