{#
    Cross-database concat_ws (concatenate with separator).

    Usage:
        {{ dbt_kanoniv.kanoniv_concat_ws(separator, fields) }}

    fields is a list of SQL expressions.
#}

{% macro kanoniv_concat_ws(separator, fields) %}
    {{ return(adapter.dispatch('kanoniv_concat_ws', 'dbt_kanoniv')(separator, fields)) }}
{% endmacro %}


{% macro default__kanoniv_concat_ws(separator, fields) %}
    concat_ws('{{ separator }}',
        {%- for field in fields %}
        {{ field }}
        {%- if not loop.last %},{% endif %}
        {%- endfor %}
    )
{% endmacro %}


{% macro snowflake__kanoniv_concat_ws(separator, fields) %}
    concat_ws('{{ separator }}',
        {%- for field in fields %}
        {{ field }}
        {%- if not loop.last %},{% endif %}
        {%- endfor %}
    )
{% endmacro %}


{% macro bigquery__kanoniv_concat_ws(separator, fields) %}
    array_to_string([
        {%- for field in fields %}
        cast({{ field }} as string)
        {%- if not loop.last %},{% endif %}
        {%- endfor %}
    ], '{{ separator }}')
{% endmacro %}
