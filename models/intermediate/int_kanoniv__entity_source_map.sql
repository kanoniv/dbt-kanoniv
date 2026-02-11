with links as (

    select * from {{ ref('stg_kanoniv__identity_links') }}

),

external_entities as (

    select * from {{ ref('stg_kanoniv__external_entities') }}

),

data_sources as (

    select * from {{ ref('stg_kanoniv__data_sources') }}

)

select
    l.link_id,
    l.canonical_entity_id,
    l.external_entity_id,
    l.confidence,
    l.link_type,
    e.external_id,
    e.entity_type,
    e.data         as external_data,
    d.source_id,
    d.source_name,
    d.source_type,
    e.created_at   as external_created_at,
    l.created_at   as linked_at

from links l

inner join external_entities e
    on l.external_entity_id = e.external_entity_id

inner join data_sources d
    on e.source_id = d.source_id
