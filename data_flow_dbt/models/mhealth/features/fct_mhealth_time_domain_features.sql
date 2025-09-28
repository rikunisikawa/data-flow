{{ config(materialized='table') }}

{%- set sensor_columns = [
    'chest_acc_x', 'chest_acc_y', 'chest_acc_z',
    'chest_ecg_1', 'chest_ecg_2',
    'left_ankle_acc_x', 'left_ankle_acc_y', 'left_ankle_acc_z',
    'left_ankle_gyro_x', 'left_ankle_gyro_y', 'left_ankle_gyro_z',
    'left_ankle_mag_x', 'left_ankle_mag_y', 'left_ankle_mag_z',
    'right_lower_arm_acc_x', 'right_lower_arm_acc_y', 'right_lower_arm_acc_z',
    'right_lower_arm_gyro_x', 'right_lower_arm_gyro_y', 'right_lower_arm_gyro_z',
    'right_lower_arm_mag_x', 'right_lower_arm_mag_y', 'right_lower_arm_mag_z'
] -%}

WITH windowed AS (
    SELECT
        window_id,
        user_id,
        activity_label,
        window_number,
        window_start,
        window_end,
        sample_index,
        {% for column in sensor_columns %}
        {{ column }}{% if not loop.last %},{% endif %}
        {% endfor %}
    FROM {{ ref('int_mhealth_windowed') }}
),

aggregated AS (
    SELECT
        window_id,
        user_id,
        activity_label,
        MIN(window_number) AS window_number,
        MIN(window_start) AS window_start,
        MAX(window_end) AS window_end,
        COUNT(*) AS sample_count,
        {% for column in sensor_columns %}
        AVG(CAST({{ column }} AS double)) AS {{ column }}_mean,
        STDDEV(CAST({{ column }} AS double)) AS {{ column }}_std,
        MIN(CAST({{ column }} AS double)) AS {{ column }}_min,
        MAX(CAST({{ column }} AS double)) AS {{ column }}_max,
        APPROX_PERCENTILE(CAST({{ column }} AS double), 0.5) AS {{ column }}_median,
        AVG(ABS(CAST({{ column }} AS double))) AS {{ column }}_mean_abs,
        SUM(POWER(CAST({{ column }} AS double), 2)) AS {{ column }}_energy,
        MAX(CAST({{ column }} AS double)) - MIN(CAST({{ column }} AS double)) AS {{ column }}_range{% if not loop.last %},{% endif %}
        {% endfor %}
    FROM windowed
    GROUP BY 1, 2, 3
)

SELECT * FROM aggregated
