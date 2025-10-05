with invalid_labels as (
    select
        user_id,
        activity_label
    from {{ ref('cleaned_activities') }}
    where activity_label <= 0
)

select *
from invalid_labels
