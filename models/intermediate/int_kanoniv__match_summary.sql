with match_results as (

    select * from {{ ref('stg_kanoniv__match_results') }}

)

select
    batch_id,
    decision,
    count(*)           as match_count,
    avg(score)         as avg_score,
    min(score)         as min_score,
    max(score)         as max_score

from match_results

group by batch_id, decision
