{#
    Normalize a phone number.

    - Removes non-numeric characters
    - Formats to E.164 (with country prefix)

    Usage:
        {{ dbt_kanoniv.normalize_phone('phone_column', 'US') }}
#}

{% macro normalize_phone(phone_column, country=none) %}
    {% set default_country = var('kanoniv_default_country', 'US') %}
    {% set effective_country = country if country else default_country %}

    {% set cleaned %}
        {{ dbt_kanoniv.kanoniv_regexp_replace(phone_column, '[^0-9]', '') }}
    {% endset %}

    case
        when '{{ effective_country }}' in ('US', 'CA') and length({{ cleaned }}) = 10
        then concat('+1', {{ cleaned }})

        when '{{ effective_country }}' in ('US', 'CA') and length({{ cleaned }}) = 11 and left({{ cleaned }}, 1) = '1'
        then concat('+', {{ cleaned }})

        when '{{ effective_country }}' = 'UK' and length({{ cleaned }}) >= 10
        then concat('+44', right({{ cleaned }}, 10))

        when length({{ cleaned }}) >= 11
        then concat('+', {{ cleaned }})

        else {{ cleaned }}
    end
{% endmacro %}
