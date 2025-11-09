{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['user_id', 'activity_label'],
    tags=['mart', 'incremental'],
    on_schema_change='sync_all_columns',
    pre_hook=[
        "{{ log('Running fact_activity_metrics incremental build', info=True) }}"
    ],
    post_hook=[
        "{{ log('Completed fact_activity_metrics incremental build', info=True) }}"
    ]
) }}

with source_data as (
    select
        fa.user_id,
        fa.activity_label,
        fa.activity_description,
        fa.chest_acc_mean,
        fa.left_ankle_acc_mean,
        fa.right_lower_arm_acc_mean,
        current_timestamp as loaded_at
    from {{ ref('featured_activities') }} fa
)

select * from source_data

{% if is_incremental() %}
where loaded_at >= {{ var('incremental_start_time', "date_trunc('day', current_timestamp) - interval '1 day'") }}
{% endif %}
