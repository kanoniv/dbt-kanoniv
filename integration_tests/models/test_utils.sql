select
    'last_4_digits' as test_case,
    {{ dbt_kanoniv.last_n_digits("'SSN: 123-45-6789'", 4) }} as actual,
    '6789' as expected
union all
select
    'hash_pii_not_null',
    case when {{ dbt_kanoniv.hash_pii("'test@example.com'") }} is not null then 'has_value' else null end,
    'has_value'
