-- Fails if any validation test case did not pass
select *
from {{ ref('test_validation') }}
where result != 'pass'
