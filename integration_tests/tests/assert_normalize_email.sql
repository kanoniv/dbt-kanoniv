-- Fails if any normalized email does not match expected
select *
from {{ ref('test_normalize_email') }}
where actual != expected
