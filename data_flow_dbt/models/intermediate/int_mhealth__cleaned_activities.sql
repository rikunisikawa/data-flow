{{ config(materialized='table') }}

WITH stg_activities AS (
    SELECT * FROM {{ ref('stg_mhealth__activities') }}
),

cleaned AS (
    SELECT
        subject_id,
        activity_label,
        -- Calculate average accelerations
        (acc_chest_x + acc_chest_y + acc_chest_z) / 3.0 AS avg_acc_chest,
        (acc_ankle_x + acc_ankle_y + acc_ankle_z) / 3.0 AS avg_acc_ankle,
        (acc_arm_x + acc_arm_y + acc_arm_z) / 3.0 AS avg_acc_arm,
        
        -- Keep other sensor data for feature engineering
        ecg_lead_1,
        ecg_lead_2,
        gyro_ankle_x,
        gyro_ankle_y,
        gyro_ankle_z,
        mag_ankle_x,
        mag_ankle_y,
        mag_ankle_z,
        gyro_arm_x,
        gyro_arm_y,
        gyro_arm_z,
        mag_arm_x,
        mag_arm_y,
        mag_arm_z
    FROM
        stg_activities
    WHERE
        -- Filter out null activity labels, which are considered invalid data
        activity_label != '0'
)

SELECT * FROM cleaned
