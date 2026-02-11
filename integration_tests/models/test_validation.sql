select
    'valid_email' as test_case,
    case when {{ dbt_kanoniv.is_valid_email("'test@example.com'") }} then 'pass' else 'fail' end as result
union all
select
    'invalid_email_no_at',
    case when not {{ dbt_kanoniv.is_valid_email("'not-an-email'") }} then 'pass' else 'fail' end
union all
select
    'valid_phone',
    case when {{ dbt_kanoniv.is_valid_phone("'(555) 123-4567'") }} then 'pass' else 'fail' end
union all
select
    'invalid_phone_short',
    case when not {{ dbt_kanoniv.is_valid_phone("'123'") }} then 'pass' else 'fail' end
