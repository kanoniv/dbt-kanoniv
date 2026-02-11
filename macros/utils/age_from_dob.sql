{#
    Calculate age in years from date of birth.

    Usage:
        {{ dbt_kanoniv.age_from_dob('dob_column') }}
#}

{% macro age_from_dob(dob_column) %}
    {{ dbt_kanoniv.kanoniv_date_diff_years(dob_column, 'current_date') }}
{% endmacro %}
