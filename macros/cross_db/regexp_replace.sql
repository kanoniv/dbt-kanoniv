{#
    Cross-database regexp_replace.

    Usage:
        {{ dbt_kanoniv.kanoniv_regexp_replace(column, pattern, replacement, flags) }}
#}

{% macro kanoniv_regexp_replace(val, pattern, replacement, flags='g') %}
    {{ return(adapter.dispatch('kanoniv_regexp_replace', 'dbt_kanoniv')(val, pattern, replacement, flags)) }}
{% endmacro %}


{% macro default__kanoniv_regexp_replace(val, pattern, replacement, flags) %}
    regexp_replace({{ val }}, '{{ pattern }}', '{{ replacement }}', '{{ flags }}')
{% endmacro %}


{% macro snowflake__kanoniv_regexp_replace(val, pattern, replacement, flags) %}
    regexp_replace({{ val }}, '{{ pattern }}', '{{ replacement }}')
{% endmacro %}


{% macro bigquery__kanoniv_regexp_replace(val, pattern, replacement, flags) %}
    regexp_replace({{ val }}, r'{{ pattern }}', '{{ replacement }}')
{% endmacro %}
