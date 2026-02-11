{#
    Extract phone area code (US format).

    Usage:
        {{ dbt_kanoniv.phone_area_code('phone_column') }}
#}

{% macro phone_area_code(phone_column) %}
    case
        when length({{ dbt_kanoniv.kanoniv_regexp_replace(phone_column, '[^0-9]', '') }}) >= 10
        then left({{ dbt_kanoniv.kanoniv_regexp_replace(phone_column, '[^0-9]', '') }}, 3)
        else null
    end
{% endmacro %}
