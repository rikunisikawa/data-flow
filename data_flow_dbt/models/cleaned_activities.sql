{{ config(materialized='table') }}

WITH source AS (

    SELECT
        *,
        -- Extract user_id from the S3 file path
        regexp_extract("$path", 'mHealth_subject(\d+)', 1) AS user_id
    FROM
        {{ source('mhealth_stage', 'raw_activities') }}

),

renamed AS (

    SELECT
        user_id,
        activity_label,
        (chest_acc_x + chest_acc_y + chest_acc_z) / 3 AS chest_acc_avg,
        (left_ankle_acc_x + left_ankle_acc_y + left_ankle_acc_z) / 3 AS left_ankle_acc_avg,
        (right_lower_arm_acc_x + right_lower_arm_acc_y + right_lower_arm_acc_z) / 3 AS right_lower_arm_acc_avg
    FROM
        source
    WHERE
        activity_label != 0

)

SELECT * FROM renamed
