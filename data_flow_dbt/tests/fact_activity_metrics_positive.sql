select *
from {{ ref('fact_activity_metrics') }}
where chest_acc_mean < 0
