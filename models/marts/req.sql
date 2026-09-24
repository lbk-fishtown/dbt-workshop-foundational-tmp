with parts as (

    select
        p_partkey as part_key,
        p_name as part_name,
        p_mfgr as manufacturer,
        p_brand as brand,
        p_type as part_type,
        p_retailprice as retail_price
    from {{ ref('stg_tpch__part') }}

),

part_suppliers as (

    select
        ps_partkey as part_key,
        ps_availqty as available_quantity,
        ps_supplycost as supply_cost
    from {{ ref('stg_tpch__partsupp') }}

),

part_margins as (

    select
        parts.part_key,
        parts.part_name,
        parts.manufacturer,
        parts.brand,
        parts.part_type,
        parts.retail_price,
        sum(part_suppliers.available_quantity) as total_quantity,
        sum(
            part_suppliers.supply_cost * part_suppliers.available_quantity
        ) / nullif(sum(part_suppliers.available_quantity), 0) as weighted_average_supply_cost,
        sum(
            (parts.retail_price - part_suppliers.supply_cost)
            * part_suppliers.available_quantity
        ) / nullif(sum(part_suppliers.available_quantity), 0) as unit_margin,
        sum(
            (parts.retail_price - part_suppliers.supply_cost)
            * part_suppliers.available_quantity
        ) as total_margin
    from parts
    inner join part_suppliers
        on parts.part_key = part_suppliers.part_key
    group by
        parts.part_key,
        parts.part_name,
        parts.manufacturer,
        parts.brand,
        parts.part_type,
        parts.retail_price

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
    from part_margins

)

select *
from ranked
where total_margin_rank <= 50
order by total_margin_rank
