{% snapshot featured_activities_snapshot %}

{{ config(
    target_schema=target.schema,
    target_database=target.database,
    strategy='check',
    unique_key=['user_id', 'activity_label'],
    check_cols=['chest_acc_mean', 'left_ankle_acc_mean', 'right_lower_arm_acc_mean', 'activity_description']
) }}

select
    fa.user_id,
    fa.activity_label,
    fa.activity_description,
    fa.chest_acc_mean,
    fa.left_ankle_acc_mean,
    fa.right_lower_arm_acc_mean
from {{ ref('featured_activities') }} fa

{% endsnapshot %}
