{{ config(
    materialized='table',
    tags=['core'],
    post_hook=[
        "{{ log('cleaned_activities built at ' ~ run_started_at, info=True) }}"
    ]
) }}

select
    user_id,
    activity_label,
    chest_acc_avg,
    left_ankle_acc_avg,
    right_lower_arm_acc_avg
from {{ ref('int_activity_features') }}
