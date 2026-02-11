{#
    Extract email domain.

    Usage:
        {{ dbt_kanoniv.email_domain('email_column') }}
#}

{% macro email_domain(email_column) %}
    lower({{ dbt_kanoniv.kanoniv_split_part(email_column, '@', 2) }})
{% endmacro %}
