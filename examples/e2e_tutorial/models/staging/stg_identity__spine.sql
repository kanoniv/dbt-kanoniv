{#
    Union all 5 source systems into a single identity spine,
    using dbt-kanoniv macros for normalization and validation.
#}

with raw_union as (

    -- CRM contacts
    select
        crm_contact_id                                    as source_id,
        'crm'                                             as source_system,
        first_name,
        last_name,
        email,
        phone,
        company_name
    from {{ ref('crm_contacts') }}

    union all

    -- Billing accounts ("Last, First" format)
    select
        billing_account_id,
        'billing',
        trim({{ dbt_kanoniv.kanoniv_split_part('account_name', ',', 2) }})  as first_name,
        trim({{ dbt_kanoniv.kanoniv_split_part('account_name', ',', 1) }})  as last_name,
        email,
        null                                                                 as phone,
        company_name
    from {{ ref('billing_accounts') }}

    union all

    -- Support users ("First Last" format)
    select
        support_user_id,
        'support',
        {{ dbt_kanoniv.kanoniv_split_part('display_name', ' ', 1) }}  as first_name,
        {{ dbt_kanoniv.kanoniv_split_part('display_name', ' ', 2) }}  as last_name,
        email,
        phone,
        company
    from {{ ref('support_users') }}

    union all

    -- App signups
    select
        app_user_id,
        'app',
        first_name,
        last_name,
        email,
        null  as phone,
        null  as company_name
    from {{ ref('app_signups') }}

    union all

    -- Partner leads
    select
        partner_lead_id,
        'partners',
        first_name,
        last_name,
        email,
        null  as phone,
        company
    from {{ ref('partner_leads') }}

),

normalized as (
    select
        source_id,
        source_system,

        -- dbt-kanoniv normalization macros
        {{ dbt_kanoniv.normalize_name('first_name') }}    as first_name,
        {{ dbt_kanoniv.normalize_name('last_name') }}     as last_name,
        {{ dbt_kanoniv.normalize_email('email') }}         as email,
        {{ dbt_kanoniv.normalize_phone('phone') }}         as phone,
        lower(trim(company_name))                          as company_name,

        -- dbt-kanoniv validation macros
        {{ dbt_kanoniv.is_valid_email('email') }}          as is_email_valid,
        {{ dbt_kanoniv.is_valid_phone('phone') }}          as is_phone_valid,

        -- dbt-kanoniv blocking keys
        {{ dbt_kanoniv.email_domain('email') }}            as email_domain,
        {{ dbt_kanoniv.name_initial('first_name') }}       as first_initial,

        -- dbt-kanoniv PII hashing
        {{ dbt_kanoniv.hash_pii('email') }}                as email_hash,

        md5(source_system || source_id)                    as record_id

    from raw_union
)

select * from normalized
