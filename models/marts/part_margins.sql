{{ config(materialized='table') }}

with parts as (

    select * from {{ ref('stg_parts') }}

),

part_suppliers as (

    select * from {{ ref('stg_part_suppliers') }}

),

part_supplier_margins as (

    select
        parts.part_key,
        parts.part_name,
        parts.manufacturer,
        parts.brand,
        parts.part_type,
        parts.retail_price,
        part_suppliers.available_quantity,
        part_suppliers.supply_cost,
        (
            parts.retail_price - part_suppliers.supply_cost
        ) * part_suppliers.available_quantity as supplier_total_margin
    from parts
    inner join part_suppliers
        on parts.part_key = part_suppliers.part_key

),

aggregated as (

    select
        part_key,
        part_name,
        manufacturer,
        brand,
        part_type,
        retail_price,
        sum(available_quantity) as total_quantity,
        (
            sum(supply_cost * available_quantity)
            / nullif(sum(available_quantity), 0)
        )::decimal(18, 4) as weighted_average_unit_cost,
        (
            retail_price
            - (
                sum(supply_cost * available_quantity)
                / nullif(sum(available_quantity), 0)
            )
        )::decimal(18, 4) as unit_margin,
        sum(supplier_total_margin)::decimal(18, 2) as total_margin
    from part_supplier_margins
    group by
        part_key,
        part_name,
        manufacturer,
        brand,
        part_type,
        retail_price

),

ranked as (

    select
        *,
        row_number() over (
            order by unit_margin desc, part_key
        ) as unit_margin_rank,
        row_number() over (
            order by total_margin desc, part_key
        ) as total_margin_rank
    from aggregated

)

select *
from ranked
