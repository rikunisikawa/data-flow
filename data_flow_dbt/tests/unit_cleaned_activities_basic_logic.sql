with input_raw as (
    select
        1 as subject_id,
        1 as activity_label,
        0.9 as chest_acc_x,
        0.3 as chest_acc_y,
        0.6 as chest_acc_z,
        0.4 as left_ankle_acc_x,
        0.5 as left_ankle_acc_y,
        0.1 as left_ankle_acc_z,
        0.2 as right_lower_arm_acc_x,
        0.4 as right_lower_arm_acc_y,
        0.6 as right_lower_arm_acc_z,
        's3://bucket/stage/subject_id=1/activity_label=1/file.parquet' as "$path"
    union all
    select
        1,
        0,
        0.1,
        0.2,
        0.3,
        0.4,
        0.5,
        0.6,
        0.7,
        0.8,
        0.9,
        's3://bucket/stage/subject_id=1/activity_label=0/file.parquet' as "$path"
),

expected as (
    select
        cast('1' as varchar) as user_id,
        cast(1 as bigint) as activity_label,
        cast(0.6 as double) as chest_acc_avg,
        cast(0.3333333333 as double) as left_ankle_acc_avg,
        cast(0.4 as double) as right_lower_arm_acc_avg
),

actual as (
    select
        cast(subject_id as varchar) as user_id,
        cast(activity_label as bigint) as activity_label,
        (chest_acc_x + chest_acc_y + chest_acc_z) / 3 as chest_acc_avg,
        (left_ankle_acc_x + left_ankle_acc_y + left_ankle_acc_z) / 3 as left_ankle_acc_avg,
        (right_lower_arm_acc_x + right_lower_arm_acc_y + right_lower_arm_acc_z) / 3 as right_lower_arm_acc_avg
    from input_raw
    where cast(activity_label as bigint) != 0
),

missing_in_actual as (
    select
        'missing_in_actual' as diff_type,
        e.user_id,
        e.activity_label,
        e.chest_acc_avg as expected_chest_acc_avg,
        cast(null as double) as actual_chest_acc_avg,
        e.left_ankle_acc_avg as expected_left_ankle_acc_avg,
        cast(null as double) as actual_left_ankle_acc_avg,
        e.right_lower_arm_acc_avg as expected_right_lower_arm_acc_avg,
        cast(null as double) as actual_right_lower_arm_acc_avg
    from expected e
    left join actual a
        on e.user_id = a.user_id
       and e.activity_label = a.activity_label
    where a.user_id is null
),

unexpected_in_actual as (
    select
        'unexpected_in_actual' as diff_type,
        a.user_id,
        a.activity_label,
        cast(null as double) as expected_chest_acc_avg,
        a.chest_acc_avg as actual_chest_acc_avg,
        cast(null as double) as expected_left_ankle_acc_avg,
        a.left_ankle_acc_avg as actual_left_ankle_acc_avg,
        cast(null as double) as expected_right_lower_arm_acc_avg,
        a.right_lower_arm_acc_avg as actual_right_lower_arm_acc_avg
    from actual a
    left join expected e
        on e.user_id = a.user_id
       and e.activity_label = a.activity_label
    where e.user_id is null
),

mismatched_values as (
    select
        'mismatched_values' as diff_type,
        e.user_id,
        e.activity_label,
        e.chest_acc_avg as expected_chest_acc_avg,
        a.chest_acc_avg as actual_chest_acc_avg,
        e.left_ankle_acc_avg as expected_left_ankle_acc_avg,
        a.left_ankle_acc_avg as actual_left_ankle_acc_avg,
        e.right_lower_arm_acc_avg as expected_right_lower_arm_acc_avg,
        a.right_lower_arm_acc_avg as actual_right_lower_arm_acc_avg
    from expected e
    join actual a
        on e.user_id = a.user_id
       and e.activity_label = a.activity_label
    where abs(e.chest_acc_avg - a.chest_acc_avg) > 1e-6
       or abs(e.left_ankle_acc_avg - a.left_ankle_acc_avg) > 1e-6
       or abs(e.right_lower_arm_acc_avg - a.right_lower_arm_acc_avg) > 1e-6
)

select * from missing_in_actual
union all
select * from unexpected_in_actual
union all
select * from mismatched_values
