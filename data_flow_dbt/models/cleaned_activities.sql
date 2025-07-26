{{ config(materialized='table') }}

SELECT
  id,
  accel_x,
  accel_y,
  accel_z,
  timestamp
FROM {{ source('mhealth', 'raw_activity') }}
WHERE accel_x IS NOT NULL
