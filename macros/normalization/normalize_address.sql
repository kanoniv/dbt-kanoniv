{#
    Normalize an address.

    - Uppercases and trims
    - Standardizes common street abbreviations

    Usage:
        {{ dbt_kanoniv.normalize_address('address_column') }}
#}

{% macro normalize_address(address_column) %}
    {% set addr = "upper(trim(" ~ address_column ~ "))" %}

    replace(
        replace(
            replace(
                replace(
                    replace(
                        {{ addr }},
                        ' STREET', ' ST'
                    ),
                    ' AVENUE', ' AVE'
                ),
                ' BOULEVARD', ' BLVD'
            ),
            ' ROAD', ' RD'
        ),
        ' DRIVE', ' DR'
    )
{% endmacro %}
