with match_results as (

    select * from {{ ref('stg_kanoniv__match_results') }}

)

select
    batch_id,
    decision,
    count(*)           as match_count,
    avg(confidence)    as avg_score,
    min(confidence)    as min_score,
    max(confidence)    as max_score

from match_results

group by batch_id, decision
