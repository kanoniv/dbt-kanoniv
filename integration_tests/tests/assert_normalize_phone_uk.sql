-- Fails if any normalized UK phone does not match expected
select *
from {{ ref('test_normalize_phone_uk') }}
where actual != expected
