with canonical as (

    select * from {{ ref('stg_kanoniv__canonical_entities') }}

),

entity_map as (

    select * from {{ ref('int_kanoniv__entity_source_map') }}

),

source_stats as (

    select
        canonical_entity_id,
        count(distinct external_entity_id)  as source_record_count,
        count(distinct source_id)           as source_count,
        min(external_created_at)            as first_seen_at,
        max(external_created_at)            as last_seen_at

    from entity_map
    group by canonical_entity_id

)

select
    c.canonical_entity_id,
    c.entity_type,
    c.data,
    coalesce(s.source_record_count, 0) as source_record_count,
    coalesce(s.source_count, 0)        as source_count,
    s.first_seen_at,
    s.last_seen_at,
    c.created_at,
    c.updated_at

from canonical c

left join source_stats s
    on c.canonical_entity_id = s.canonical_entity_id
