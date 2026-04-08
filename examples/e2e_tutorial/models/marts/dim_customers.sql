{#
    Golden customer records via survivorship.
    Each resolved entity gets the best value per field,
    prioritizing CRM > Billing > Support > App > Partners.
#}

with clustered as (
    select
        c.resolved_entity_id,
        s.*
    from {{ ref('int_identity__clusters') }} c
    inner join {{ ref('stg_identity__spine') }} s
        on c.record_id = s.record_id
),

survivorship as (
    select
        resolved_entity_id,

        first_value(first_name) over (
            partition by resolved_entity_id
            order by
                case source_system
                    when 'crm'      then 1
                    when 'billing'  then 2
                    when 'app'      then 3
                    when 'support'  then 4
                    when 'partners' then 5
                end,
                case when first_name is not null then 0 else 1 end
            rows between unbounded preceding and unbounded following
        ) as golden_first_name,

        first_value(last_name) over (
            partition by resolved_entity_id
            order by
                case source_system
                    when 'crm'      then 1
                    when 'billing'  then 2
                    when 'app'      then 3
                    when 'support'  then 4
                    when 'partners' then 5
                end,
                case when last_name is not null then 0 else 1 end
            rows between unbounded preceding and unbounded following
        ) as golden_last_name,

        first_value(email) over (
            partition by resolved_entity_id
            order by
                case source_system
                    when 'crm'      then 1
                    when 'billing'  then 2
                    when 'app'      then 3
                    when 'support'  then 4
                    when 'partners' then 5
                end,
                case when email is not null then 0 else 1 end
            rows between unbounded preceding and unbounded following
        ) as golden_email,

        first_value(phone) over (
            partition by resolved_entity_id
            order by
                case source_system
                    when 'crm'      then 1
                    when 'support'  then 2
                    when 'billing'  then 3
                    when 'app'      then 4
                    when 'partners' then 5
                end,
                case when phone is not null and phone <> '' then 0 else 1 end
            rows between unbounded preceding and unbounded following
        ) as golden_phone,

        first_value(company_name) over (
            partition by resolved_entity_id
            order by
                case source_system
                    when 'crm'      then 1
                    when 'billing'  then 2
                    when 'partners' then 3
                    when 'support'  then 4
                    when 'app'      then 5
                end,
                case when company_name is not null and company_name <> '' then 0 else 1 end
            rows between unbounded preceding and unbounded following
        ) as golden_company

    from clustered
)

select distinct * from survivorship
