{#
    Resolution quality metrics.
    Shows input vs output counts, merge rate, and compression ratio.
#}

with spine as (
    select count(*) as total_input_records
    from {{ ref('stg_identity__spine') }}
),

customers as (
    select count(*) as total_golden_records
    from {{ ref('dim_customers') }}
),

clusters as (
    select
        resolved_entity_id,
        count(*) as cluster_size
    from {{ ref('int_identity__clusters') }}
    group by resolved_entity_id
),

cluster_stats as (
    select
        count(*) as total_clusters,
        avg(cluster_size) as avg_cluster_size,
        max(cluster_size) as max_cluster_size,
        count(*) filter (where cluster_size = 1) as singletons,
        count(*) filter (where cluster_size > 1) as merged_clusters
    from clusters
)

select
    s.total_input_records,
    c.total_golden_records,
    round((1.0 - c.total_golden_records::numeric / s.total_input_records) * 100, 1) as merge_rate_pct,
    round(s.total_input_records::numeric / c.total_golden_records, 1) as compression_ratio,
    cs.singletons,
    cs.merged_clusters,
    round(cs.avg_cluster_size, 2) as avg_cluster_size,
    cs.max_cluster_size
from spine s
cross join customers c
cross join cluster_stats cs
