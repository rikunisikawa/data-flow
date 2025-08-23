
WITH stg_mhealth_raw AS (
    SELECT * FROM {{ ref('stg_mhealth_raw') }}
),

filtered AS (
    SELECT
        *
    FROM
        stg_mhealth_raw
    WHERE
        activity_label != 0
)

SELECT * FROM filtered
