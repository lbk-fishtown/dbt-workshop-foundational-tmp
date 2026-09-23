with parts as (

    select
        p_partkey as part_key,
        p_name as part_name,
        p_mfgr as manufacturer,
        p_brand as brand,
        p_type as part_type,
        p_size as part_size,
        p_container as container,
        p_retailprice as retail_price
    from {{ ref('stg_tpch__part') }}

),

part_suppliers as (

    select
        ps_partkey as part_key,
        ps_suppkey as supplier_key,
        ps_availqty as available_quantity,
        ps_supplycost as unit_cost
    from {{ ref('stg_tpch__partsupp') }}

),

supplier_margins as (

    select
        parts.part_key,
        parts.part_name,
        parts.manufacturer,
        parts.brand,
        parts.part_type,
        parts.part_size,
        parts.container,
        parts.retail_price,
        part_suppliers.supplier_key,
        part_suppliers.available_quantity,
        part_suppliers.unit_cost,
        parts.retail_price - part_suppliers.unit_cost as supplier_unit_margin,
        (parts.retail_price - part_suppliers.unit_cost)
            * part_suppliers.available_quantity as supplier_total_margin
    from parts
    inner join part_suppliers
        on parts.part_key = part_suppliers.part_key

),

part_margin_totals as (

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
        sum(available_quantity) as total_quantity,
        sum(unit_cost * available_quantity) as total_inventory_cost,
        sum(supplier_total_margin) as total_margin
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

part_unit_margins as (

    select
        part_key,
        part_name,
        manufacturer,
        brand,
        part_type,
        part_size,
        container,
        retail_price,
        supplier_count,
        total_quantity,
        (total_inventory_cost / nullif(total_quantity, 0))::decimal(18, 6)
            as weighted_average_unit_cost,
        (total_margin / nullif(total_quantity, 0))::decimal(18, 6) as unit_margin
    from part_margin_totals

),

part_margins as (

    select
        *,
        (unit_margin * total_quantity)::decimal(18, 2) as total_margin
    from part_unit_margins

),

ranked_parts as (

    select
        *,
        dense_rank() over (
            order by unit_margin desc
        ) as unit_margin_rank,
        row_number() over (
            order by total_margin desc, part_key
        ) as total_margin_rank
    from part_margins

)

select *
from ranked_parts
where total_margin_rank <= 50
order by total_margin_rank
