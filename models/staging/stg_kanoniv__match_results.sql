with source as (

    select * from {{ source('kanoniv', 'match_results') }}

)

select
    id              as match_id,
    batch_id,
    entity_a_id,
    entity_b_id,
    score,
    decision,
    details,
    created_at

from source
