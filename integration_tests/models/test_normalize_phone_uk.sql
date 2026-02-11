select
    id,
    raw_phone,
    {{ dbt_kanoniv.normalize_phone('raw_phone', 'UK') }} as actual,
    expected

from {{ ref('seed_phones') }}
where raw_phone is not null and country = 'UK'
