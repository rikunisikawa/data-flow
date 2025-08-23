WITH source AS (

    SELECT * FROM {{ source('mhealth_stage', 'raw_activities') }}

),

renamed AS (

    SELECT
        subject_id,
        activity_id,
        "timestamp",
        acc_chest_x,
        acc_chest_y,
        acc_chest_z,
        ecg_lead_1,
        ecg_lead_2,
        acc_left_ankle_x,
        acc_left_ankle_y,
        acc_left_ankle_z,
        gyro_left_ankle_x,
        gyro_left_ankle_y,
        gyro_left_ankle_z,
        mag_left_ankle_x,
        mag_left_ankle_y,
        mag_left_ankle_z,
        acc_right_wrist_x,
        acc_right_wrist_y,
        acc_right_wrist_z,
        gyro_right_wrist_x,
        gyro_right_wrist_y,
        gyro_right_wrist_z,
        mag_right_wrist_x,
        mag_right_wrist_y,
        mag_right_wrist_z,
        "label" AS activity_label
    FROM source

)

SELECT
    -- 代理キーの生成
    {{ dbt_utils.generate_surrogate_key(['subject_id', 'timestamp']) }} AS activity_sk,
    *,
    "timestamp" as measured_at
FROM renamed
