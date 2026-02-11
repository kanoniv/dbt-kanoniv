{#
    Validate that a phone number has at least 10 digits.

    Usage:
        {{ dbt_kanoniv.is_valid_phone('phone_column') }}
#}

{% macro is_valid_phone(phone_column) %}
    length({{ dbt_kanoniv.kanoniv_regexp_replace(phone_column, '[^0-9]', '') }}) >= 10
{% endmacro %}
