{#
    Score candidate pairs from blocking.
    Uses normalized fields from dbt-kanoniv macros.
#}

with pairs as (
    select * from {{ ref('int_identity__blocking') }}
),

spine as (
    select * from {{ ref('stg_identity__spine') }}
),

scored as (
    select
        p.record_a,
        p.record_b,

        -- Email: exact match on normalized email (dbt-kanoniv normalize_email)
        case
            when a.email = b.email then 5.0
            when a.email is null or b.email is null then 0.0
            when {{ dbt_kanoniv.kanoniv_split_part('a.email', '@', 1) }}
               = {{ dbt_kanoniv.kanoniv_split_part('b.email', '@', 1) }} then 3.0
            else -1.5
        end as email_score,

        -- Phone: exact match on E.164 (dbt-kanoniv normalize_phone)
        case
            when a.phone = b.phone and a.phone is not null and a.phone <> '' then 4.0
            when a.phone is null or b.phone is null or a.phone = '' or b.phone = '' then 0.0
            else -0.5
        end as phone_score,

        -- Name: trigram similarity on normalized names (dbt-kanoniv normalize_name)
        -- Uses pg_trgm (PG 9.1+). Swap to jaro_winkler_similarity() on PG 17+.
        similarity(a.first_name, b.first_name) * 2.0 as first_name_score,
        similarity(a.last_name, b.last_name) * 2.0   as last_name_score,

        -- Company: trigram similarity on lowered company
        similarity(
            coalesce(a.company_name, ''),
            coalesce(b.company_name, '')
        ) * 1.5 as company_score

    from pairs p
    inner join spine a on p.record_a = a.record_id
    inner join spine b on p.record_b = b.record_id
),

final as (
    select
        *,
        (email_score + phone_score + first_name_score + last_name_score + company_score) as total_score
    from scored
)

select * from final
where total_score >= 4.0
