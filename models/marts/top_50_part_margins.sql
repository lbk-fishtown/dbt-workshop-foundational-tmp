with parts as (

    select
        p_partkey,
        p_name,
        p_mfgr,
        p_brand,
        p_type,
        p_retailprice
    from {{ ref('stg_tpch__part') }}

),

part_suppliers as (

    select
        ps_partkey,
        ps_suppkey,
        ps_availqty,
        ps_supplycost
    from {{ ref('stg_tpch__partsupp') }}

),

supplier_margins as (

    select
        parts.p_partkey as part_key,
        parts.p_name as part_name,
        parts.p_mfgr as manufacturer,
        parts.p_brand as brand,
        parts.p_type as part_type,
        parts.p_retailprice as unit_retail_price,
        part_suppliers.ps_suppkey as supplier_key,
        part_suppliers.ps_availqty as available_quantity,
        part_suppliers.ps_supplycost as unit_cost,
        parts.p_retailprice - part_suppliers.ps_supplycost as unit_margin,
        (
            parts.p_retailprice - part_suppliers.ps_supplycost
        ) * part_suppliers.ps_availqty as total_margin
    from parts
    inner join part_suppliers
        on parts.p_partkey = part_suppliers.ps_partkey

),

part_margins as (

    select
        part_key,
        part_name,
        manufacturer,
        brand,
        part_type,
        unit_retail_price,
        sum(available_quantity) as total_quantity,
        sum(unit_cost * available_quantity)
            / nullif(sum(available_quantity), 0) as weighted_average_unit_cost,
        sum(total_margin)
            / nullif(sum(available_quantity), 0) as unit_margin,
        sum(total_margin) as total_margin
    from supplier_margins
    group by 1, 2, 3, 4, 5, 6

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

select
    part_key,
    part_name,
    manufacturer,
    brand,
    part_type,
    unit_retail_price,
    weighted_average_unit_cost,
    unit_margin,
    total_quantity,
    total_margin,
    unit_margin_rank,
    total_margin_rank
from ranked
where total_margin_rank <= 50
order by total_margin_rank
