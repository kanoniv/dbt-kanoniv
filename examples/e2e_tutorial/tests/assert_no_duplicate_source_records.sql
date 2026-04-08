-- Each source record should appear in exactly one cluster
select record_id, count(*) as cnt
from {{ ref('int_identity__clusters') }}
group by record_id
having count(*) > 1
