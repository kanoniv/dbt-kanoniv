-- Fails if any normalized name does not match expected
select *
from {{ ref('test_normalize_name') }}
where actual != expected
