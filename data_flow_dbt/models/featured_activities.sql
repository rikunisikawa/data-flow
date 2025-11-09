{{ config(
    materialized='table',
    tags=['mart'],
    pre_hook=[
        "{{ log('Starting aggregation for featured_activities', info=True) }}"
    ]
) }}

with cleaned_data as (
    select *
    from {{ ref('cleaned_activities') }}
),

activity_dim as (
    select * from {{ ref('activity_labels') }}
),

featured as (
    select
        c.user_id,
        c.activity_label,
        dim.description as activity_description,
        avg(c.chest_acc_avg) as chest_acc_mean,
        stddev(c.chest_acc_avg) as chest_acc_std,
        min(c.chest_acc_avg) as chest_acc_min,
        max(c.chest_acc_avg) as chest_acc_max,
        avg(c.left_ankle_acc_avg) as left_ankle_acc_mean,
        stddev(c.left_ankle_acc_avg) as left_ankle_acc_std,
        min(c.left_ankle_acc_avg) as left_ankle_acc_min,
        max(c.left_ankle_acc_avg) as left_ankle_acc_max,
        avg(c.right_lower_arm_acc_avg) as right_lower_arm_acc_mean,
        stddev(c.right_lower_arm_acc_avg) as right_lower_arm_acc_std,
        min(c.right_lower_arm_acc_avg) as right_lower_arm_acc_min,
        max(c.right_lower_arm_acc_avg) as right_lower_arm_acc_max
    from cleaned_data c
    left join activity_dim dim on c.activity_label = cast(dim.activity_label as bigint)
    group by
        c.user_id,
        c.activity_label,
        dim.description
)

select * from featured
