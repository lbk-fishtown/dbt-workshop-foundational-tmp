with parts as (

    select * from {{ ref('stg_tpch__part') }}

),

part_suppliers as (

    select * from {{ ref('stg_tpch__partsupp') }}

),

part_margin_components as (

    select
        parts.part_key,
        parts.part_name,
        parts.manufacturer,
        parts.brand,
        parts.part_type,
        parts.part_size,
        parts.container,
        parts.retail_price,
        part_suppliers.available_quantity,
        part_suppliers.supply_cost,
        part_suppliers.supply_cost * part_suppliers.available_quantity as total_cost,
        (parts.retail_price - part_suppliers.supply_cost)
            * part_suppliers.available_quantity as total_margin
    from parts
    inner join part_suppliers
        on parts.part_key = part_suppliers.part_key

),

part_margins as (

    select
        part_key,
        part_name,
        manufacturer,
        brand,
        part_type,
        part_size,
        container,
        retail_price,
        sum(available_quantity) as total_quantity,
        sum(total_cost) / nullif(sum(available_quantity), 0) as unit_cost,
        retail_price
            - (sum(total_cost) / nullif(sum(available_quantity), 0)) as unit_margin,
        sum(total_margin) as total_margin
    from part_margin_components
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
        rank() over (order by unit_margin desc) as unit_margin_rank,
        row_number() over (
            order by total_margin desc, part_key
        ) as total_margin_rank
    from part_margins

)

select *
from ranked
where total_margin_rank <= 50
order by total_margin_rank
