-- Fails if any utility macro output does not match expected
select *
from {{ ref('test_utils') }}
where actual != expected
