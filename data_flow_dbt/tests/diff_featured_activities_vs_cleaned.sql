with aggregated as (
    select
        user_id,
        activity_label,
        round(avg(chest_acc_avg), 6) as chest_acc_mean,
        round(stddev(chest_acc_avg), 6) as chest_acc_std,
        round(min(chest_acc_avg), 6) as chest_acc_min,
        round(max(chest_acc_avg), 6) as chest_acc_max,
        round(avg(left_ankle_acc_avg), 6) as left_ankle_acc_mean,
        round(stddev(left_ankle_acc_avg), 6) as left_ankle_acc_std,
        round(min(left_ankle_acc_avg), 6) as left_ankle_acc_min,
        round(max(left_ankle_acc_avg), 6) as left_ankle_acc_max,
        round(avg(right_lower_arm_acc_avg), 6) as right_lower_arm_acc_mean,
        round(stddev(right_lower_arm_acc_avg), 6) as right_lower_arm_acc_std,
        round(min(right_lower_arm_acc_avg), 6) as right_lower_arm_acc_min,
        round(max(right_lower_arm_acc_avg), 6) as right_lower_arm_acc_max
    from {{ ref('cleaned_activities') }}
    group by user_id, activity_label
),

featured as (
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
    from {{ ref('featured_activities') }}
),

missing_in_featured as (
    select
        'missing_in_featured' as diff_type,
        agg.user_id,
        agg.activity_label,
        agg.chest_acc_mean,
        agg.chest_acc_std,
        agg.chest_acc_min,
        agg.chest_acc_max,
        agg.left_ankle_acc_mean,
        agg.left_ankle_acc_std,
        agg.left_ankle_acc_min,
        agg.left_ankle_acc_max,
        agg.right_lower_arm_acc_mean,
        agg.right_lower_arm_acc_std,
        agg.right_lower_arm_acc_min,
        agg.right_lower_arm_acc_max,
        'expected aggregate row missing from featured_activities' as details
    from aggregated agg
    left join featured feat
        on agg.user_id = feat.user_id
       and agg.activity_label = feat.activity_label
    where feat.user_id is null
),

unexpected_in_featured as (
    select
        'unexpected_in_featured' as diff_type,
        feat.user_id,
        feat.activity_label,
        feat.chest_acc_mean,
        feat.chest_acc_std,
        feat.chest_acc_min,
        feat.chest_acc_max,
        feat.left_ankle_acc_mean,
        feat.left_ankle_acc_std,
        feat.left_ankle_acc_min,
        feat.left_ankle_acc_max,
        feat.right_lower_arm_acc_mean,
        feat.right_lower_arm_acc_std,
        feat.right_lower_arm_acc_min,
        feat.right_lower_arm_acc_max,
        'unexpected aggregate row produced by featured_activities' as details
    from featured feat
    left join aggregated agg
        on agg.user_id = feat.user_id
       and agg.activity_label = feat.activity_label
    where agg.user_id is null
),

metric_mismatches as (
    select
        'metric_mismatch' as diff_type,
        agg.user_id,
        agg.activity_label,
        agg.chest_acc_mean,
        agg.chest_acc_std,
        agg.chest_acc_min,
        agg.chest_acc_max,
        agg.left_ankle_acc_mean,
        agg.left_ankle_acc_std,
        agg.left_ankle_acc_min,
        agg.left_ankle_acc_max,
        agg.right_lower_arm_acc_mean,
        agg.right_lower_arm_acc_std,
        agg.right_lower_arm_acc_min,
        agg.right_lower_arm_acc_max,
        'feature row present but metric values differ from recomputed aggregate' as details
    from aggregated agg
    join featured feat
        on agg.user_id = feat.user_id
       and agg.activity_label = feat.activity_label
    where abs(coalesce(agg.chest_acc_mean, 0) - coalesce(feat.chest_acc_mean, 0)) > 1e-6
       or (agg.chest_acc_std is null) <> (feat.chest_acc_std is null)
       or (agg.chest_acc_std is not null and feat.chest_acc_std is not null and abs(agg.chest_acc_std - feat.chest_acc_std) > 1e-6)
       or abs(coalesce(agg.chest_acc_min, 0) - coalesce(feat.chest_acc_min, 0)) > 1e-6
       or abs(coalesce(agg.chest_acc_max, 0) - coalesce(feat.chest_acc_max, 0)) > 1e-6
       or abs(coalesce(agg.left_ankle_acc_mean, 0) - coalesce(feat.left_ankle_acc_mean, 0)) > 1e-6
       or (agg.left_ankle_acc_std is null) <> (feat.left_ankle_acc_std is null)
       or (agg.left_ankle_acc_std is not null and feat.left_ankle_acc_std is not null and abs(agg.left_ankle_acc_std - feat.left_ankle_acc_std) > 1e-6)
       or abs(coalesce(agg.left_ankle_acc_min, 0) - coalesce(feat.left_ankle_acc_min, 0)) > 1e-6
       or abs(coalesce(agg.left_ankle_acc_max, 0) - coalesce(feat.left_ankle_acc_max, 0)) > 1e-6
       or abs(coalesce(agg.right_lower_arm_acc_mean, 0) - coalesce(feat.right_lower_arm_acc_mean, 0)) > 1e-6
       or (agg.right_lower_arm_acc_std is null) <> (feat.right_lower_arm_acc_std is null)
       or (agg.right_lower_arm_acc_std is not null and feat.right_lower_arm_acc_std is not null and abs(agg.right_lower_arm_acc_std - feat.right_lower_arm_acc_std) > 1e-6)
       or abs(coalesce(agg.right_lower_arm_acc_min, 0) - coalesce(feat.right_lower_arm_acc_min, 0)) > 1e-6
       or abs(coalesce(agg.right_lower_arm_acc_max, 0) - coalesce(feat.right_lower_arm_acc_max, 0)) > 1e-6
)

select * from missing_in_featured
union all
select * from unexpected_in_featured
union all
select * from metric_mismatches
