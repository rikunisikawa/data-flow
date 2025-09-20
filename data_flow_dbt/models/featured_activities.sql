{{ config(materialized='table') }}

WITH cleaned_data AS (
    SELECT
        user_id,
        activity_label,
        chest_acc_avg,
        left_ankle_acc_avg,
        right_lower_arm_acc_avg
    FROM {{ ref('cleaned_activities') }}
),

featured AS (
    SELECT
        user_id,
        activity_label,
        -- Chest Accelerometer Features
        avg(chest_acc_avg) AS chest_acc_mean,
        stddev(chest_acc_avg) AS chest_acc_std,
        min(chest_acc_avg) AS chest_acc_min,
        max(chest_acc_avg) AS chest_acc_max,

        -- Left Ankle Accelerometer Features
        avg(left_ankle_acc_avg) AS left_ankle_acc_mean,
        stddev(left_ankle_acc_avg) AS left_ankle_acc_std,
        min(left_ankle_acc_avg) AS left_ankle_acc_min,
        max(left_ankle_acc_avg) AS left_ankle_acc_max,

        -- Right Lower Arm Accelerometer Features
        avg(right_lower_arm_acc_avg) AS right_lower_arm_acc_mean,
        stddev(right_lower_arm_acc_avg) AS right_lower_arm_acc_std,
        min(right_lower_arm_acc_avg) AS right_lower_arm_acc_min,
        max(right_lower_arm_acc_avg) AS right_lower_arm_acc_max
    FROM
        cleaned_data
    GROUP BY
        user_id,
        activity_label
)

SELECT * FROM featured
