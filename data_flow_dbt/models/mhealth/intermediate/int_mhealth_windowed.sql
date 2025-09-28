{{ config(materialized='table') }}

{%- set window_size_seconds = var('mhealth_window_size_seconds', 2.56) -%}
{%- set overlap_percentage = var('mhealth_window_overlap_percentage', 0.5) -%}
{%- set sampling_frequency_hz = var('mhealth_sampling_frequency_hz', 50) -%}
{%- set window_size_rows = (window_size_seconds * sampling_frequency_hz)|round(0, 'floor')|int -%}
{%- set window_size_rows = 1 if window_size_rows < 1 else window_size_rows -%}
{%- set step_size_rows = (window_size_rows * (1 - overlap_percentage))|round(0, 'floor')|int -%}
{%- set step_size_rows = 1 if step_size_rows < 1 else step_size_rows -%}

WITH base AS (
    SELECT
        CAST(subject_id AS varchar) AS user_id,
        CAST(activity_label AS bigint) AS activity_label,
        chest_acc_x,
        chest_acc_y,
        chest_acc_z,
        chest_ecg_1,
        chest_ecg_2,
        left_ankle_acc_x,
        left_ankle_acc_y,
        left_ankle_acc_z,
        left_ankle_gyro_x,
        left_ankle_gyro_y,
        left_ankle_gyro_z,
        left_ankle_mag_x,
        left_ankle_mag_y,
        left_ankle_mag_z,
        right_lower_arm_acc_x,
        right_lower_arm_acc_y,
        right_lower_arm_acc_z,
        right_lower_arm_gyro_x,
        right_lower_arm_gyro_y,
        right_lower_arm_gyro_z,
        right_lower_arm_mag_x,
        right_lower_arm_mag_y,
        right_lower_arm_mag_z,
        row_number() OVER (
            PARTITION BY subject_id, activity_label
            ORDER BY
                "$path",
                chest_acc_x,
                chest_acc_y,
                chest_acc_z,
                chest_ecg_1,
                chest_ecg_2,
                left_ankle_acc_x,
                left_ankle_acc_y,
                left_ankle_acc_z,
                left_ankle_gyro_x,
                left_ankle_gyro_y,
                left_ankle_gyro_z,
                left_ankle_mag_x,
                left_ankle_mag_y,
                left_ankle_mag_z,
                right_lower_arm_acc_x,
                right_lower_arm_acc_y,
                right_lower_arm_acc_z,
                right_lower_arm_gyro_x,
                right_lower_arm_gyro_y,
                right_lower_arm_gyro_z,
                right_lower_arm_mag_x,
                right_lower_arm_mag_y,
                right_lower_arm_mag_z
        ) - 1 AS sample_index
    FROM {{ source('mhealth_stage', 'raw_activities') }}
    WHERE CAST(activity_label AS bigint) != 0
),

sample_summary AS (
    SELECT
        user_id,
        activity_label,
        MAX(sample_index) AS max_sample_index
    FROM base
    GROUP BY 1, 2
),

window_starts AS (
    SELECT
        user_id,
        activity_label,
        window_start,
        ROW_NUMBER() OVER (
            PARTITION BY user_id, activity_label
            ORDER BY window_start
        ) AS window_number
    FROM sample_summary
    CROSS JOIN UNNEST(
        sequence(
            0,
            greatest(max_sample_index - {{ window_size_rows }} + 1, 0),
            {{ step_size_rows }}
        )
    ) AS t(window_start)
),

windowed AS (
    SELECT
        b.user_id,
        b.activity_label,
        ws.window_number,
        ws.window_start,
        ws.window_start + {{ window_size_rows }} - 1 AS window_end,
        lpad(CAST(ws.window_number AS varchar), 6, '0') AS window_number_padded,
        b.sample_index,
        b.chest_acc_x,
        b.chest_acc_y,
        b.chest_acc_z,
        b.chest_ecg_1,
        b.chest_ecg_2,
        b.left_ankle_acc_x,
        b.left_ankle_acc_y,
        b.left_ankle_acc_z,
        b.left_ankle_gyro_x,
        b.left_ankle_gyro_y,
        b.left_ankle_gyro_z,
        b.left_ankle_mag_x,
        b.left_ankle_mag_y,
        b.left_ankle_mag_z,
        b.right_lower_arm_acc_x,
        b.right_lower_arm_acc_y,
        b.right_lower_arm_acc_z,
        b.right_lower_arm_gyro_x,
        b.right_lower_arm_gyro_y,
        b.right_lower_arm_gyro_z,
        b.right_lower_arm_mag_x,
        b.right_lower_arm_mag_y,
        b.right_lower_arm_mag_z
    FROM base b
    INNER JOIN window_starts ws
        ON b.user_id = ws.user_id
        AND b.activity_label = ws.activity_label
        AND b.sample_index BETWEEN ws.window_start AND ws.window_start + {{ window_size_rows }} - 1
)

SELECT
    user_id,
    activity_label,
    window_number,
    CONCAT(user_id, '_', lpad(CAST(activity_label AS varchar), 3, '0'), '_', window_number_padded) AS window_id,
    window_start,
    window_end,
    sample_index,
    chest_acc_x,
    chest_acc_y,
    chest_acc_z,
    chest_ecg_1,
    chest_ecg_2,
    left_ankle_acc_x,
    left_ankle_acc_y,
    left_ankle_acc_z,
    left_ankle_gyro_x,
    left_ankle_gyro_y,
    left_ankle_gyro_z,
    left_ankle_mag_x,
    left_ankle_mag_y,
    left_ankle_mag_z,
    right_lower_arm_acc_x,
    right_lower_arm_acc_y,
    right_lower_arm_acc_z,
    right_lower_arm_gyro_x,
    right_lower_arm_gyro_y,
    right_lower_arm_gyro_z,
    right_lower_arm_mag_x,
    right_lower_arm_mag_y,
    right_lower_arm_mag_z
FROM windowed
