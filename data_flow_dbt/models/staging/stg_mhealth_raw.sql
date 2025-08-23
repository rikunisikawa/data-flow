WITH source AS (
    SELECT * FROM {{ source('mhealth_stage', 'raw_activities') }}
),

add_row_number AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY subject_id, activity_label ORDER BY 1) as reading_id
    FROM
        source
),

renamed AS (
    SELECT
        "subject_id",
        "activity_label",
        "reading_id",
        "chest_acc_x" AS chest_acceleration_x,
        "chest_acc_y" AS chest_acceleration_y,
        "chest_acc_z" AS chest_acceleration_z,
        "chest_ecg_1" AS chest_ecg_lead_1,
        "chest_ecg_2" AS chest_ecg_lead_2,
        "left_ankle_acc_x" AS left_ankle_acceleration_x,
        "left_ankle_acc_y" AS left_ankle_acceleration_y,
        "left_ankle_acc_z" AS left_ankle_acceleration_z,
        "left_ankle_gyro_x" AS left_ankle_gyroscope_x,
        "left_ankle_gyro_y" AS left_ankle_gyroscope_y,
        "left_ankle_gyro_z" AS left_ankle_gyroscope_z,
        "left_ankle_mag_x" AS left_ankle_magnetometer_x,
        "left_ankle_mag_y" AS left_ankle_magnetometer_y,
        "left_ankle_mag_z" AS left_ankle_magnetometer_z,
        "right_lower_arm_acc_x" AS right_lower_arm_acceleration_x,
        "right_lower_arm_acc_y" AS right_lower_arm_acceleration_y,
        "right_lower_arm_acc_z" AS right_lower_arm_acceleration_z,
        "right_lower_arm_gyro_x" AS right_lower_arm_gyroscope_x,
        "right_lower_arm_gyro_y" AS right_lower_arm_gyroscope_y,
        "right_lower_arm_gyro_z" AS right_lower_arm_gyroscope_z,
        "right_lower_arm_mag_x" AS right_lower_arm_magnetometer_x,
        "right_lower_arm_mag_y" AS right_lower_arm_magnetometer_y,
        "right_lower_arm_mag_z" AS right_lower_arm_magnetometer_z
    FROM add_row_number
)

SELECT * FROM renamed