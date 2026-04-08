{#
    Generate candidate pairs using dbt-kanoniv blocking keys.
    Multiple blocking strategies reduce the O(n^2) comparison space.
#}

with spine as (
    select * from {{ ref('stg_identity__spine') }}
),

blocking_keys as (

    -- Key 1: exact normalized email
    select record_id, email as block_key, 'email' as block_type
    from spine
    where email is not null

    union all

    -- Key 2: exact phone (E.164 via dbt-kanoniv normalize_phone)
    select record_id, phone, 'phone'
    from spine
    where phone is not null and phone <> ''

    union all

    -- Key 3: composite blocking key (first initial + last name)
    select
        record_id,
        {{ dbt_kanoniv.blocking_key(['first_initial', 'last_name']) }},
        'name'
    from spine
    where first_name is not null and last_name is not null

    union all

    -- Key 4: composite blocking key (email domain + last name)
    select
        record_id,
        {{ dbt_kanoniv.blocking_key(['email_domain', 'last_name']) }},
        'domain_name'
    from spine
    where email is not null and last_name is not null

    union all

    -- Key 5: composite blocking key (last name + company)
    select
        record_id,
        {{ dbt_kanoniv.blocking_key(['last_name', 'company_name']) }},
        'name_company'
    from spine
    where last_name is not null and company_name is not null and company_name <> ''

),

pairs as (
    select
        a.record_id  as record_a,
        b.record_id  as record_b,
        count(*)      as shared_keys
    from blocking_keys a
    inner join blocking_keys b
        on a.block_key = b.block_key
        and a.record_id < b.record_id
    group by 1, 2
)

select * from pairs
