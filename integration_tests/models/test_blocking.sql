select
    'email_domain' as test_case,
    {{ dbt_kanoniv.email_domain("'user@example.com'") }} as actual,
    'example.com' as expected
union all
select
    'phone_area_code',
    {{ dbt_kanoniv.phone_area_code("'(555) 123-4567'") }},
    '555'
union all
select
    'name_initial_first',
    {{ dbt_kanoniv.name_initial("'John Smith'", 'first') }},
    'J'
union all
select
    'name_initial_last',
    {{ dbt_kanoniv.name_initial("'John Smith'", 'last') }},
    'S'
