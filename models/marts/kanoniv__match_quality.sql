with match_summary as (

    select * from {{ ref('int_kanoniv__match_summary') }}

),

batch_runs as (

    select * from {{ ref('stg_kanoniv__batch_runs') }}

)

select
    b.batch_id,
    b.status       as batch_status,
    b.started_at,
    b.completed_at,
    m.decision,
    m.match_count,
    m.avg_score,
    m.min_score,
    m.max_score

from match_summary m

inner join batch_runs b
    on m.batch_id = b.batch_id
