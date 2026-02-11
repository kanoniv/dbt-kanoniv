with source as (

    select * from {{ source('kanoniv', 'data_sources') }}

)

select
    id              as source_id,
    name            as source_name,
    source_type,
    config,
    created_at,
    updated_at

from source
