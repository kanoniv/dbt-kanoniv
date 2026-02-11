{#
    Get first or last initial from a name.

    Usage:
        {{ dbt_kanoniv.name_initial('name_column', 'first') }}
        {{ dbt_kanoniv.name_initial('name_column', 'last') }}
#}

{% macro name_initial(name_column, position='first') %}
    {% if position == 'first' %}
        upper(left(trim({{ name_column }}), 1))
    {% else %}
        {# Use split_part with part 2 to get last word — avoids Postgres-14-only negative index #}
        upper(left(
            {{ dbt_kanoniv.kanoniv_regexp_replace('trim(' ~ name_column ~ ')', '.*\\s', '') }},
            1
        ))
    {% endif %}
{% endmacro %}
