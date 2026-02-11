{#
    One-way hash for PII data.
    Returns a hex-encoded SHA-256 hash.

    Usage:
        {{ dbt_kanoniv.hash_pii('email_column') }}
        {{ dbt_kanoniv.hash_pii('email_column', salt='my_secret') }}
#}

{% macro hash_pii(column_name, salt=none) %}
    {% if salt %}
        {{ dbt_kanoniv.kanoniv_hash_sha256("concat(cast(" ~ column_name ~ " as varchar), '" ~ salt ~ "')") }}
    {% else %}
        {{ dbt_kanoniv.kanoniv_hash_sha256("cast(" ~ column_name ~ " as varchar)") }}
    {% endif %}
{% endmacro %}
