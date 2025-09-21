{{ config(materialized='table') }}

WITH source AS (

    SELECT
        *,
        -- Extract user_id from partition path or filename as fallback
        regexp_extract("$path", 'subject_id=(\\d+)', 1) AS user_id_from_partition,
        regexp_extract("$path", 'mHealth_subject(\\d+)', 1) AS user_id_from_filename
    FROM
        {{ source('mhealth_stage', 'raw_activities') }}

),

renamed AS (

    SELECT
        -- Prefer Glue partition key if present; otherwise fallback to path regexes
        CAST(subject_id AS varchar) AS user_id,
        CAST(activity_label AS bigint) AS activity_label,
        (chest_acc_x + chest_acc_y + chest_acc_z) / 3 AS chest_acc_avg,
        (left_ankle_acc_x + left_ankle_acc_y + left_ankle_acc_z) / 3 AS left_ankle_acc_avg,
        (right_lower_arm_acc_x + right_lower_arm_acc_y + right_lower_arm_acc_z) / 3 AS right_lower_arm_acc_avg
    FROM
        source
    WHERE
        CAST(activity_label AS bigint) != 0

)

SELECT * FROM renamed
