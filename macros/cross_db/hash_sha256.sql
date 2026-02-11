{#
    Cross-database SHA-256 hash returning a hex string.

    Usage:
        {{ dbt_kanoniv.kanoniv_hash_sha256(column) }}
#}

{% macro kanoniv_hash_sha256(val) %}
    {{ return(adapter.dispatch('kanoniv_hash_sha256', 'dbt_kanoniv')(val)) }}
{% endmacro %}


{% macro default__kanoniv_hash_sha256(val) %}
    encode(sha256(cast({{ val }} as bytea)), 'hex')
{% endmacro %}


{% macro snowflake__kanoniv_hash_sha256(val) %}
    sha2(cast({{ val }} as varchar), 256)
{% endmacro %}


{% macro bigquery__kanoniv_hash_sha256(val) %}
    to_hex(sha256(cast({{ val }} as bytes)))
{% endmacro %}
