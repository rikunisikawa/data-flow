with cleaned_input as (
    select '1' as user_id, cast(1 as bigint) as activity_label, 0.2 as chest_acc_avg, 0.4 as left_ankle_acc_avg, 0.6 as right_lower_arm_acc_avg
    union all
    select '1', cast(1 as bigint), 0.4, 0.2, 0.8
    union all
    select '1', cast(2 as bigint), 0.1, 0.3, 0.5
    union all
    select '2', cast(1 as bigint), 0.5, 0.7, 0.9
),

expected as (
    select * from (values
        ('1', cast(1 as bigint), 0.3, 0.1414213562, 0.2, 0.4, 0.3, 0.1414213562, 0.2, 0.4, 0.7, 0.1414213562, 0.6, 0.8),
        ('1', cast(2 as bigint), 0.1, cast(null as double), 0.1, 0.1, 0.3, cast(null as double), 0.3, 0.3, 0.5, cast(null as double), 0.5, 0.5),
        ('2', cast(1 as bigint), 0.5, cast(null as double), 0.5, 0.5, 0.7, cast(null as double), 0.7, 0.7, 0.9, cast(null as double), 0.9, 0.9)
    ) as t(
        user_id,
        activity_label,
        chest_acc_mean,
        chest_acc_std,
        chest_acc_min,
        chest_acc_max,
        left_ankle_acc_mean,
        left_ankle_acc_std,
        left_ankle_acc_min,
        left_ankle_acc_max,
        right_lower_arm_acc_mean,
        right_lower_arm_acc_std,
        right_lower_arm_acc_min,
        right_lower_arm_acc_max
    )
),

rounded_expected as (
    select
        user_id,
        activity_label,
        round(chest_acc_mean, 6) as chest_acc_mean,
        round(chest_acc_std, 6) as chest_acc_std,
        round(chest_acc_min, 6) as chest_acc_min,
        round(chest_acc_max, 6) as chest_acc_max,
        round(left_ankle_acc_mean, 6) as left_ankle_acc_mean,
        round(left_ankle_acc_std, 6) as left_ankle_acc_std,
        round(left_ankle_acc_min, 6) as left_ankle_acc_min,
        round(left_ankle_acc_max, 6) as left_ankle_acc_max,
        round(right_lower_arm_acc_mean, 6) as right_lower_arm_acc_mean,
        round(right_lower_arm_acc_std, 6) as right_lower_arm_acc_std,
        round(right_lower_arm_acc_min, 6) as right_lower_arm_acc_min,
        round(right_lower_arm_acc_max, 6) as right_lower_arm_acc_max
    from expected
),

actual as (
    select
        user_id,
        activity_label,
        avg(chest_acc_avg) as chest_acc_mean,
        stddev(chest_acc_avg) as chest_acc_std,
        min(chest_acc_avg) as chest_acc_min,
        max(chest_acc_avg) as chest_acc_max,
        avg(left_ankle_acc_avg) as left_ankle_acc_mean,
        stddev(left_ankle_acc_avg) as left_ankle_acc_std,
        min(left_ankle_acc_avg) as left_ankle_acc_min,
        max(left_ankle_acc_avg) as left_ankle_acc_max,
        avg(right_lower_arm_acc_avg) as right_lower_arm_acc_mean,
        stddev(right_lower_arm_acc_avg) as right_lower_arm_acc_std,
        min(right_lower_arm_acc_avg) as right_lower_arm_acc_min,
        max(right_lower_arm_acc_avg) as right_lower_arm_acc_max
    from cleaned_input
    group by user_id, activity_label
),

rounded_actual as (
    select
        user_id,
        activity_label,
        round(chest_acc_mean, 6) as chest_acc_mean,
        round(chest_acc_std, 6) as chest_acc_std,
        round(chest_acc_min, 6) as chest_acc_min,
        round(chest_acc_max, 6) as chest_acc_max,
        round(left_ankle_acc_mean, 6) as left_ankle_acc_mean,
        round(left_ankle_acc_std, 6) as left_ankle_acc_std,
        round(left_ankle_acc_min, 6) as left_ankle_acc_min,
        round(left_ankle_acc_max, 6) as left_ankle_acc_max,
        round(right_lower_arm_acc_mean, 6) as right_lower_arm_acc_mean,
        round(right_lower_arm_acc_std, 6) as right_lower_arm_acc_std,
        round(right_lower_arm_acc_min, 6) as right_lower_arm_acc_min,
        round(right_lower_arm_acc_max, 6) as right_lower_arm_acc_max
    from actual
),

missing_in_actual as (
    select
        'missing_in_actual' as diff_type,
        e.user_id,
        e.activity_label,
        e.chest_acc_mean as expected_chest_acc_mean,
        cast(null as double) as actual_chest_acc_mean,
        e.chest_acc_std as expected_chest_acc_std,
        cast(null as double) as actual_chest_acc_std,
        e.chest_acc_min as expected_chest_acc_min,
        cast(null as double) as actual_chest_acc_min,
        e.chest_acc_max as expected_chest_acc_max,
        cast(null as double) as actual_chest_acc_max,
        e.left_ankle_acc_mean as expected_left_ankle_acc_mean,
        cast(null as double) as actual_left_ankle_acc_mean,
        e.left_ankle_acc_std as expected_left_ankle_acc_std,
        cast(null as double) as actual_left_ankle_acc_std,
        e.left_ankle_acc_min as expected_left_ankle_acc_min,
        cast(null as double) as actual_left_ankle_acc_min,
        e.left_ankle_acc_max as expected_left_ankle_acc_max,
        cast(null as double) as actual_left_ankle_acc_max,
        e.right_lower_arm_acc_mean as expected_right_lower_arm_acc_mean,
        cast(null as double) as actual_right_lower_arm_acc_mean,
        e.right_lower_arm_acc_std as expected_right_lower_arm_acc_std,
        cast(null as double) as actual_right_lower_arm_acc_std,
        e.right_lower_arm_acc_min as expected_right_lower_arm_acc_min,
        cast(null as double) as actual_right_lower_arm_acc_min,
        e.right_lower_arm_acc_max as expected_right_lower_arm_acc_max,
        cast(null as double) as actual_right_lower_arm_acc_max
    from rounded_expected e
    left join rounded_actual a
        on e.user_id = a.user_id
       and e.activity_label = a.activity_label
    where a.user_id is null
),

unexpected_in_actual as (
    select
        'unexpected_in_actual' as diff_type,
        a.user_id,
        a.activity_label,
        cast(null as double) as expected_chest_acc_mean,
        a.chest_acc_mean as actual_chest_acc_mean,
        cast(null as double) as expected_chest_acc_std,
        a.chest_acc_std as actual_chest_acc_std,
        cast(null as double) as expected_chest_acc_min,
        a.chest_acc_min as actual_chest_acc_min,
        cast(null as double) as expected_chest_acc_max,
        a.chest_acc_max as actual_chest_acc_max,
        cast(null as double) as expected_left_ankle_acc_mean,
        a.left_ankle_acc_mean as actual_left_ankle_acc_mean,
        cast(null as double) as expected_left_ankle_acc_std,
        a.left_ankle_acc_std as actual_left_ankle_acc_std,
        cast(null as double) as expected_left_ankle_acc_min,
        a.left_ankle_acc_min as actual_left_ankle_acc_min,
        cast(null as double) as expected_left_ankle_acc_max,
        a.left_ankle_acc_max as actual_left_ankle_acc_max,
        cast(null as double) as expected_right_lower_arm_acc_mean,
        a.right_lower_arm_acc_mean as actual_right_lower_arm_acc_mean,
        cast(null as double) as expected_right_lower_arm_acc_std,
        a.right_lower_arm_acc_std as actual_right_lower_arm_acc_std,
        cast(null as double) as expected_right_lower_arm_acc_min,
        a.right_lower_arm_acc_min as actual_right_lower_arm_acc_min,
        cast(null as double) as expected_right_lower_arm_acc_max,
        a.right_lower_arm_acc_max as actual_right_lower_arm_acc_max
    from rounded_actual a
    left join rounded_expected e
        on e.user_id = a.user_id
       and e.activity_label = a.activity_label
    where e.user_id is null
),

mismatched_values as (
    select
        'mismatched_values' as diff_type,
        e.user_id,
        e.activity_label,
        e.chest_acc_mean as expected_chest_acc_mean,
        a.chest_acc_mean as actual_chest_acc_mean,
        e.chest_acc_std as expected_chest_acc_std,
        a.chest_acc_std as actual_chest_acc_std,
        e.chest_acc_min as expected_chest_acc_min,
        a.chest_acc_min as actual_chest_acc_min,
        e.chest_acc_max as expected_chest_acc_max,
        a.chest_acc_max as actual_chest_acc_max,
        e.left_ankle_acc_mean as expected_left_ankle_acc_mean,
        a.left_ankle_acc_mean as actual_left_ankle_acc_mean,
        e.left_ankle_acc_std as expected_left_ankle_acc_std,
        a.left_ankle_acc_std as actual_left_ankle_acc_std,
        e.left_ankle_acc_min as expected_left_ankle_acc_min,
        a.left_ankle_acc_min as actual_left_ankle_acc_min,
        e.left_ankle_acc_max as expected_left_ankle_acc_max,
        a.left_ankle_acc_max as actual_left_ankle_acc_max,
        e.right_lower_arm_acc_mean as expected_right_lower_arm_acc_mean,
        a.right_lower_arm_acc_mean as actual_right_lower_arm_acc_mean,
        e.right_lower_arm_acc_std as expected_right_lower_arm_acc_std,
        a.right_lower_arm_acc_std as actual_right_lower_arm_acc_std,
        e.right_lower_arm_acc_min as expected_right_lower_arm_acc_min,
        a.right_lower_arm_acc_min as actual_right_lower_arm_acc_min,
        e.right_lower_arm_acc_max as expected_right_lower_arm_acc_max,
        a.right_lower_arm_acc_max as actual_right_lower_arm_acc_max
    from rounded_expected e
    join rounded_actual a
        on e.user_id = a.user_id
       and e.activity_label = a.activity_label
    where abs(coalesce(e.chest_acc_mean, 0) - coalesce(a.chest_acc_mean, 0)) > 1e-6
       or (e.chest_acc_std is null) <> (a.chest_acc_std is null)
       or (e.chest_acc_std is not null and a.chest_acc_std is not null and abs(e.chest_acc_std - a.chest_acc_std) > 1e-6)
       or abs(coalesce(e.chest_acc_min, 0) - coalesce(a.chest_acc_min, 0)) > 1e-6
       or abs(coalesce(e.chest_acc_max, 0) - coalesce(a.chest_acc_max, 0)) > 1e-6
       or abs(coalesce(e.left_ankle_acc_mean, 0) - coalesce(a.left_ankle_acc_mean, 0)) > 1e-6
       or (e.left_ankle_acc_std is null) <> (a.left_ankle_acc_std is null)
       or (e.left_ankle_acc_std is not null and a.left_ankle_acc_std is not null and abs(e.left_ankle_acc_std - a.left_ankle_acc_std) > 1e-6)
       or abs(coalesce(e.left_ankle_acc_min, 0) - coalesce(a.left_ankle_acc_min, 0)) > 1e-6
       or abs(coalesce(e.left_ankle_acc_max, 0) - coalesce(a.left_ankle_acc_max, 0)) > 1e-6
       or abs(coalesce(e.right_lower_arm_acc_mean, 0) - coalesce(a.right_lower_arm_acc_mean, 0)) > 1e-6
       or (e.right_lower_arm_acc_std is null) <> (a.right_lower_arm_acc_std is null)
       or (e.right_lower_arm_acc_std is not null and a.right_lower_arm_acc_std is not null and abs(e.right_lower_arm_acc_std - a.right_lower_arm_acc_std) > 1e-6)
       or abs(coalesce(e.right_lower_arm_acc_min, 0) - coalesce(a.right_lower_arm_acc_min, 0)) > 1e-6
       or abs(coalesce(e.right_lower_arm_acc_max, 0) - coalesce(a.right_lower_arm_acc_max, 0)) > 1e-6
)

select * from missing_in_actual
union all
select * from unexpected_in_actual
union all
select * from mismatched_values
