-- Most golden records should have an email from survivorship.
-- Allow up to 15% without email (some source records legitimately lack email).
with stats as (
    select
        count(*) as total,
        count(*) filter (where golden_email is null) as missing_email
    from {{ ref('dim_customers') }}
)
select *
from stats
where missing_email::numeric / total > 0.15
