with source as (

    select * from {{ source('kanoniv', 'canonical_entities') }}

)

select
    id              as canonical_entity_id,
    entity_type,
    canonical_data,
    field_provenance,
    confidence_score,
    version,
    state,
    created_at,
    updated_at

from source
