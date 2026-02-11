{#
    Cross-database year difference between two dates.

    Usage:
        {{ dbt_kanoniv.kanoniv_date_diff_years(start_date, end_date) }}
#}

{% macro kanoniv_date_diff_years(start_date, end_date) %}
    {{ return(adapter.dispatch('kanoniv_date_diff_years', 'dbt_kanoniv')(start_date, end_date)) }}
{% endmacro %}


{% macro default__kanoniv_date_diff_years(start_date, end_date) %}
    extract(year from age(cast({{ end_date }} as date), cast({{ start_date }} as date)))
{% endmacro %}


{% macro snowflake__kanoniv_date_diff_years(start_date, end_date) %}
    datediff('year', cast({{ start_date }} as date), cast({{ end_date }} as date))
{% endmacro %}


{% macro bigquery__kanoniv_date_diff_years(start_date, end_date) %}
    date_diff(cast({{ end_date }} as date), cast({{ start_date }} as date), year)
{% endmacro %}
