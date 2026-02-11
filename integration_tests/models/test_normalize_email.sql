select
    id,
    raw_email,
    {{ dbt_kanoniv.normalize_email('raw_email') }} as actual,
    expected

from {{ ref('seed_emails') }}
where raw_email is not null
