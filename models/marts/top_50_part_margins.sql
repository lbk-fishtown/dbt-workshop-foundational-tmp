{{
    config(
        materialized='table'
    )
}}

with parts as (

    select * from {{ ref('stg_tpch__part') }}

),

part_suppliers as (

    select * from {{ ref('stg_tpch__partsupp') }}

),

supplier_margins as (

    select
        parts.part_key,
        parts.name as part_name,
        parts.manufacturer,
        parts.brand,
        parts.type as part_type,
        parts.size as part_size,
        parts.container,
        parts.retail_price,
        part_suppliers.supplier_key,
        part_suppliers.available_quantity,
        part_suppliers.supply_cost,
        parts.retail_price * part_suppliers.available_quantity as potential_revenue,
        part_suppliers.supply_cost * part_suppliers.available_quantity as inventory_cost,
        (parts.retail_price - part_suppliers.supply_cost)
            * part_suppliers.available_quantity as total_margin
    from parts
    inner join part_suppliers
        on parts.part_key = part_suppliers.part_key

),

part_profitability as (

    select
        part_key,
        part_name,
        manufacturer,
        brand,
        part_type,
        part_size,
        container,
        retail_price,
        count(distinct supplier_key) as supplier_count,
        sum(available_quantity) as available_quantity,
        round(
            sum(inventory_cost) / nullif(sum(available_quantity), 0),
            2
        ) as weighted_average_supply_cost,
        round(sum(potential_revenue), 2) as potential_revenue,
        round(sum(inventory_cost), 2) as inventory_cost,
        round(sum(total_margin), 2) as total_margin,
        round(
            100 * sum(total_margin) / nullif(sum(potential_revenue), 0),
            4
        ) as profit_margin_percentage
    from supplier_margins
    group by
        part_key,
        part_name,
        manufacturer,
        brand,
        part_type,
        part_size,
        container,
        retail_price

),

ranked as (

    select
        *,
        row_number() over (
            order by total_margin desc, part_key
        ) as total_margin_rank,
        row_number() over (
            order by profit_margin_percentage desc, total_margin desc, part_key
        ) as profit_margin_rank
    from part_profitability

)

select *
from ranked
where total_margin_rank <= 50
order by total_margin_rank
