{#
    Cross-database split_part.

    Usage:
        {{ dbt_kanoniv.kanoniv_split_part(column, delimiter, part_number) }}

    Note: part_number is 1-indexed. Negative values are not supported cross-db.
#}

{% macro kanoniv_split_part(val, delimiter, part_number) %}
    {{ return(adapter.dispatch('kanoniv_split_part', 'dbt_kanoniv')(val, delimiter, part_number)) }}
{% endmacro %}


{% macro default__kanoniv_split_part(val, delimiter, part_number) %}
    split_part({{ val }}, '{{ delimiter }}', {{ part_number }})
{% endmacro %}


{% macro snowflake__kanoniv_split_part(val, delimiter, part_number) %}
    split_part({{ val }}, '{{ delimiter }}', {{ part_number }})
{% endmacro %}


{% macro bigquery__kanoniv_split_part(val, delimiter, part_number) %}
    split({{ val }}, '{{ delimiter }}')[safe_offset({{ part_number }} - 1)]
{% endmacro %}
