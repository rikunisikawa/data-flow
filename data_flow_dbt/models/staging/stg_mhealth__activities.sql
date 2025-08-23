
WITH source AS (
    SELECT * FROM {{ source('mhealth_source', 'raw_activities') }}
),

renamed AS (
    SELECT
        -- Identifiers
        "subject_id",
        "activity_label",

        -- Chest Accelerometer
        "acceleration_chest_x" AS acc_chest_x,
        "acceleration_chest_y" AS acc_chest_y,
        "acceleration_chest_z" AS acc_chest_z,

        -- Electrocardiogram
        "electrocardiogram_lead_1" AS ecg_lead_1,
        "electrocardiogram_lead_2" AS ecg_lead_2,

        -- Ankle Accelerometer
        "acceleration_ankle_x" AS acc_ankle_x,
        "acceleration_ankle_y" AS acc_ankle_y,
        "acceleration_ankle_z" AS acc_ankle_z,

        -- Ankle Gyroscope
        "gyroscope_ankle_x" AS gyro_ankle_x,
        "gyroscope_ankle_y" AS gyro_ankle_y,
        "gyroscope_ankle_z" AS gyro_ankle_z,

        -- Ankle Magnetometer
        "magnetometer_ankle_x" AS mag_ankle_x,
        "magnetometer_ankle_y" AS mag_ankle_y,
        "magnetometer_ankle_z" AS mag_ankle_z,

        -- Right Lower Arm Accelerometer
        "acceleration_right_lower_arm_x" AS acc_arm_x,
        "acceleration_right_lower_arm_y" AS acc_arm_y,
        "acceleration_right_lower_arm_z" AS acc_arm_z,

        -- Right Lower Arm Gyroscope
        "gyroscope_right_lower_arm_x" AS gyro_arm_x,
        "gyroscope_right_lower_arm_y" AS gyro_arm_y,
        "gyroscope_right_lower_arm_z" AS gyro_arm_z,

        -- Right Lower Arm Magnetometer
        "magnetometer_right_lower_arm_x" AS mag_arm_x,
        "magnetometer_right_lower_arm_y" AS mag_arm_y,
        "magnetometer_right_lower_arm_z" AS mag_arm_z,

        -- Label
        "label" AS activity_code
    FROM source
)

SELECT
    -- Identifiers
    CAST(subject_id AS VARCHAR) AS subject_id,
    CAST(activity_label AS VARCHAR) AS activity_label,
    
    -- Sensor readings (casted to DOUBLE)
    CAST(acc_chest_x AS DOUBLE) AS acc_chest_x,
    CAST(acc_chest_y AS DOUBLE) AS acc_chest_y,
    CAST(acc_chest_z AS DOUBLE) AS acc_chest_z,
    CAST(ecg_lead_1 AS DOUBLE) AS ecg_lead_1,
    CAST(ecg_lead_2 AS DOUBLE) AS ecg_lead_2,
    CAST(acc_ankle_x AS DOUBLE) AS acc_ankle_x,
    CAST(acc_ankle_y AS DOUBLE) AS acc_ankle_y,
    CAST(acc_ankle_z AS DOUBLE) AS acc_ankle_z,
    CAST(gyro_ankle_x AS DOUBLE) AS gyro_ankle_x,
    CAST(gyro_ankle_y AS DOUBLE) AS gyro_ankle_y,
    CAST(gyro_ankle_z AS DOUBLE) AS gyro_ankle_z,
    CAST(mag_ankle_x AS DOUBLE) AS mag_ankle_x,
    CAST(mag_ankle_y AS DOUBLE) AS mag_ankle_y,
    CAST(mag_ankle_z AS DOUBLE) AS mag_ankle_z,
    CAST(acc_arm_x AS DOUBLE) AS acc_arm_x,
    CAST(acc_arm_y AS DOUBLE) AS acc_arm_y,
    CAST(acc_arm_z AS DOUBLE) AS acc_arm_z,
    CAST(gyro_arm_x AS DOUBLE) AS gyro_arm_x,
    CAST(gyro_arm_y AS DOUBLE) AS gyro_arm_y,
    CAST(gyro_arm_z AS DOUBLE) AS gyro_arm_z,
    CAST(mag_arm_x AS DOUBLE) AS mag_arm_x,
    CAST(mag_arm_y AS DOUBLE) AS mag_arm_y,
    CAST(mag_arm_z AS DOUBLE) AS mag_arm_z,

    -- Label
    CAST(activity_code AS BIGINT) AS activity_code

FROM renamed
