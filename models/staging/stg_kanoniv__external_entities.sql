with source as (

    select * from {{ source('kanoniv', 'external_entities') }}

)

select
    id              as external_entity_id,
    data_source_id,
    external_id,
    entity_type,
    raw_data,
    normalized_data,
    ingested_at,
    batch_id,
    content_hash

from source
