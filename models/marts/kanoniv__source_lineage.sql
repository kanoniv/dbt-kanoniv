with entity_map as (

    select * from {{ ref('int_kanoniv__entity_source_map') }}

)

select
    canonical_entity_id,
    external_entity_id,
    external_id,
    entity_type,
    source_name,
    source_type,
    confidence,
    link_type,
    external_created_at,
    linked_at

from entity_map
