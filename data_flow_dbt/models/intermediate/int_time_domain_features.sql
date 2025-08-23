
WITH int_cleansed_activities AS (
    SELECT * FROM {{ ref('int_cleansed_activities') }}
),

-- Add a unique row identifier
add_row_number AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY subject_id, activity_label ORDER BY 1) as reading_id
    FROM
        int_cleansed_activities
),

-- Define window size and step
-- Assuming 50Hz sampling rate, 2.56s window is 128 readings.
-- 50% overlap means a step of 64 readings.
window_params AS (
    SELECT
        128 AS window_size,
        64 AS step_size
),

-- Generate window identifiers
windowing AS (
    SELECT
        *,
        floor((reading_id - 1) / (SELECT step_size FROM window_params)) AS window_id
    FROM
        add_row_number
),

-- Calculate time domain features
time_domain_features AS (
    SELECT
        subject_id,
        activity_label,
        window_id,
        AVG(chest_acceleration_x) AS avg_chest_acc_x,
        STDDEV(chest_acceleration_x) AS std_chest_acc_x,
        MIN(chest_acceleration_x) AS min_chest_acc_x,
        MAX(chest_acceleration_x) AS max_chest_acc_x,
        AVG(chest_acceleration_y) AS avg_chest_acc_y,
        STDDEV(chest_acceleration_y) AS std_chest_acc_y,
        MIN(chest_acceleration_y) AS min_chest_acc_y,
        MAX(chest_acceleration_y) AS max_chest_acc_y,
        AVG(chest_acceleration_z) AS avg_chest_acc_z,
        STDDEV(chest_acceleration_z) AS std_chest_acc_z,
        MIN(chest_acceleration_z) AS min_chest_acc_z,
        MAX(chest_acceleration_z) AS max_chest_acc_z
        -- Add more features for other sensors here
    FROM
        windowing
    GROUP BY
        subject_id,
        activity_label,
        window_id
)

SELECT * FROM time_domain_features
