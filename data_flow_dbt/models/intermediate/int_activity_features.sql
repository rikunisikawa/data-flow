{{ config(
    materialized='ephemeral',
    tags=['intermediate']
) }}

select
    user_id_raw as user_id,
    activity_label,
    {{ three_axis_average('chest_acc_x', 'chest_acc_y', 'chest_acc_z') }} as chest_acc_avg,
    {{ three_axis_average('left_ankle_acc_x', 'left_ankle_acc_y', 'left_ankle_acc_z') }} as left_ankle_acc_avg,
    {{ three_axis_average('right_lower_arm_acc_x', 'right_lower_arm_acc_y', 'right_lower_arm_acc_z') }} as right_lower_arm_acc_avg
from {{ ref('stg_mhealth_activities') }}
