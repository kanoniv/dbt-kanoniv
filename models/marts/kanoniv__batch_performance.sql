with batch_runs as (

    select * from {{ ref('stg_kanoniv__batch_runs') }}

),

match_summary as (

    select
        batch_id,
        sum(match_count)    as total_comparisons,
        avg(avg_score)      as overall_avg_score

    from {{ ref('int_kanoniv__match_summary') }}
    group by batch_id

)

select
    b.batch_id,
    b.status,
    b.started_at,
    b.completed_at,
    b.stats,
    coalesce(m.total_comparisons, 0)    as total_comparisons,
    m.overall_avg_score,
    b.created_at

from batch_runs b

left join match_summary m
    on b.batch_id = m.batch_id
