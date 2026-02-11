with source as (

    select * from {{ source('kanoniv', 'batch_runs') }}

)

select
    id              as batch_id,
    status,
    started_at,
    completed_at,
    stats,
    created_at

from source
