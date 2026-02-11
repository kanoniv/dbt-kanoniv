{#
    Normalize an email address.

    - Lowercases and trims
    - Optionally removes dots from Gmail local parts

    Usage:
        {{ dbt_kanoniv.normalize_email('email_column') }}
#}

{% macro normalize_email(email_column) %}
    {% set normalize_gmail = var('kanoniv_email_normalize_gmail', true) %}

    {% if normalize_gmail %}
        case
            when lower(trim({{ email_column }})) like '%@gmail.com'
            then concat(
                replace({{ dbt_kanoniv.kanoniv_split_part('lower(trim(' ~ email_column ~ '))', '@', 1) }}, '.', ''),
                '@gmail.com'
            )
            else lower(trim({{ email_column }}))
        end
    {% else %}
        lower(trim({{ email_column }}))
    {% endif %}
{% endmacro %}
