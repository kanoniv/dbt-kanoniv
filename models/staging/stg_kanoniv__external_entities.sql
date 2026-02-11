with source as (

    select * from {{ source('kanoniv', 'external_entities') }}

)

select
    id              as external_entity_id,
    source_id,
    external_id,
    entity_type,
    data,
    created_at,
    updated_at

from source
