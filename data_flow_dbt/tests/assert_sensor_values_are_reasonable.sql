
-- tests/assert_sensor_values_are_reasonable.sql

-- This test fails if any chest acceleration reading is outside the range of -20 to 20.
SELECT
    *
FROM
    {{ ref('stg_mhealth_raw') }}
WHERE
    chest_acceleration_x NOT BETWEEN -20 AND 20
    OR chest_acceleration_y NOT BETWEEN -20 AND 20
    OR chest_acceleration_z NOT BETWEEN -20 AND 20
