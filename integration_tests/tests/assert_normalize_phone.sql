-- Fails if any normalized US phone does not match expected
select *
from {{ ref('test_normalize_phone') }}
where actual != expected
