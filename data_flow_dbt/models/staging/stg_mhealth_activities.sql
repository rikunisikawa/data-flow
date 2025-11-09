{{ config(
    materialized='view',
    tags=['staging'],
    persist_docs={'relation': true, 'columns': true},
    contract={'enforced': true}
) }}

with source_data as (
    select
        *,
        {{ activity_coalesce_user_id('cast(subject_id as varchar)', '"$path"', '"$path"') }} as user_id_raw
    from {{ source('mhealth_stage', 'raw_activities') }}
)

select
    user_id_raw,
    cast(activity_label as bigint) as activity_label,
    cast(chest_acc_x as double) as chest_acc_x,
    cast(chest_acc_y as double) as chest_acc_y,
    cast(chest_acc_z as double) as chest_acc_z,
    cast(left_ankle_acc_x as double) as left_ankle_acc_x,
    cast(left_ankle_acc_y as double) as left_ankle_acc_y,
    cast(left_ankle_acc_z as double) as left_ankle_acc_z,
    cast(right_lower_arm_acc_x as double) as right_lower_arm_acc_x,
    cast(right_lower_arm_acc_y as double) as right_lower_arm_acc_y,
    cast(right_lower_arm_acc_z as double) as right_lower_arm_acc_z
from source_data
where cast(activity_label as bigint) != {{ var('invalid_activity_label', 0) }}
