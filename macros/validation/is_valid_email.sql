{#
    Validate email format.

    Usage:
        {{ dbt_kanoniv.is_valid_email('email_column') }}
#}

{% macro is_valid_email(email_column) %}
    {{ dbt_kanoniv.kanoniv_regexp_match(email_column, '^[a-zA-Z0-9._%+\\-]+@[a-zA-Z0-9.\\-]+\\.[a-zA-Z]{2,}$') }}
{% endmacro %}
