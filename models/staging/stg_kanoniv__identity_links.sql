with source as (

    select * from {{ source('kanoniv', 'identity_links') }}

)

select
    id                  as link_id,
    canonical_entity_id,
    external_entity_id,
    confidence,
    link_type,
    created_at,
    updated_at

from source
