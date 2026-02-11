{#
    Normalize a name.

    - Uppercases and trims
    - Optionally removes common titles and suffixes

    Usage:
        {{ dbt_kanoniv.normalize_name('name_column') }}
        {{ dbt_kanoniv.normalize_name('name_column', strip_extra=false) }}
#}

{% macro normalize_name(name_column, strip_extra=true) %}
    {% set cleaned = "trim(" ~ name_column ~ ")" %}

    {% if strip_extra %}
        {{ dbt_kanoniv.kanoniv_regexp_replace(
            'upper(' ~ cleaned ~ ')',
            '^(MR|MRS|MS|DR|PROF)\\.?\\s+|\\s+(JR|SR|II|III|IV|ESQ|MD|PHD)$',
            ''
        ) }}
    {% else %}
        upper({{ cleaned }})
    {% endif %}
{% endmacro %}
