{#
    Extract last N digits from a string.
    Useful for SSN-4 or card last-4 matching.

    Usage:
        {{ dbt_kanoniv.last_n_digits('ssn_column', 4) }}
#}

{% macro last_n_digits(column_name, n=4) %}
    right({{ dbt_kanoniv.kanoniv_regexp_replace("cast(" ~ column_name ~ " as varchar)", '[^0-9]', '') }}, {{ n }})
{% endmacro %}
