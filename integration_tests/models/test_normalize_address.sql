select
    id,
    raw_address,
    {{ dbt_kanoniv.normalize_address('raw_address') }} as actual,
    expected

from {{ ref('seed_addresses') }}
where raw_address is not null
