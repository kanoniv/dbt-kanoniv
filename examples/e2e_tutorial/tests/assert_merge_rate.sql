-- Merge rate should be between 30% and 80%
-- (sanity check: too low = nothing matched, too high = over-merging)
select *
from {{ ref('fct_resolution_metrics') }}
where merge_rate_pct < 30 or merge_rate_pct > 80
