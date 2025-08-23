
WITH int_time_domain_features AS (
    SELECT * FROM {{ ref('int_time_domain_features') }}
)

-- This model is a placeholder for the final features table.
-- In a real scenario, it would join time domain and frequency domain features.
SELECT * FROM int_time_domain_features
