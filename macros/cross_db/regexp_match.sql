{#
    Cross-database regex match (returns boolean expression).

    Usage:
        {{ dbt_kanoniv.kanoniv_regexp_match(column, pattern) }}
#}

{% macro kanoniv_regexp_match(val, pattern) %}
    {{ return(adapter.dispatch('kanoniv_regexp_match', 'dbt_kanoniv')(val, pattern)) }}
{% endmacro %}


{% macro default__kanoniv_regexp_match(val, pattern) %}
    ({{ val }} ~ '{{ pattern }}')
{% endmacro %}


{% macro snowflake__kanoniv_regexp_match(val, pattern) %}
    rlike({{ val }}, '{{ pattern }}')
{% endmacro %}


{% macro bigquery__kanoniv_regexp_match(val, pattern) %}
    regexp_contains({{ val }}, r'{{ pattern }}')
{% endmacro %}
