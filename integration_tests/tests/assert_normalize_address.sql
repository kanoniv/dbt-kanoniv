-- Fails if any normalized address does not match expected
select *
from {{ ref('test_normalize_address') }}
where actual != expected
