{{ config(materialized='table') }}

WITH source AS (

    SELECT *
    FROM {{ source('fitbit_raw', 'raw_events') }}

)

SELECT
    event_id,
    source,
    user_id,
    fitbit_user_id,
    event_type,
    try(from_iso8601_timestamp(event_time)) AS event_time,
    try(from_iso8601_timestamp(ingest_time)) AS ingest_time,
    schema_version,
    payload
FROM source
