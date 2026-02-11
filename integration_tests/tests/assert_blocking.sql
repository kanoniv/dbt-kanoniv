-- Fails if any blocking macro output does not match expected
select *
from {{ ref('test_blocking') }}
where actual != expected
