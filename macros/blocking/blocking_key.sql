{#
    Generate a blocking key from multiple fields.

    Blocking keys reduce the comparison space by grouping
    records that share common attributes.

    Usage:
        {{ dbt_kanoniv.blocking_key(['email_domain', 'zip_code']) }}
#}

{% macro blocking_key(fields) %}
    {% set coalesced = [] %}
    {%- for field in fields %}
        {% do coalesced.append("coalesce(cast(" ~ field ~ " as varchar), '')") %}
    {%- endfor %}

    {{ dbt_kanoniv.kanoniv_concat_ws('|', coalesced) }}
{% endmacro %}
