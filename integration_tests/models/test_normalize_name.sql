select
    id,
    raw_name,
    trim({{ dbt_kanoniv.normalize_name('raw_name') }}) as actual,
    expected

from {{ ref('seed_names') }}
where raw_name is not null
