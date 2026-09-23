with parts as (

    select
        p_partkey as part_key,
        p_name as product_name,
        p_mfgr as manufacturer,
        p_brand as brand,
        p_type as product_type,
        p_retailprice as unit_retail_price

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

product_supplier_margins as (

    select
        parts.part_key,
        parts.product_name,
        parts.manufacturer,
        parts.brand,
        parts.product_type,
        parts.unit_retail_price,
        part_suppliers.supplier_key,
        part_suppliers.available_quantity,
        part_suppliers.unit_cost,
        parts.unit_retail_price - part_suppliers.unit_cost as unit_margin,
        (
            parts.unit_retail_price - part_suppliers.unit_cost
        ) * part_suppliers.available_quantity as total_margin

    from parts
    inner join part_suppliers
        on parts.part_key = part_suppliers.part_key

),

product_margins as (

    select
        part_key,
        product_name,
        manufacturer,
        brand,
        product_type,
        unit_retail_price,
        sum(available_quantity) as total_quantity,
        sum(total_margin) / nullif(sum(available_quantity), 0) as unit_margin,
        sum(total_margin) as total_margin

    from product_supplier_margins
    group by
        part_key,
        product_name,
        manufacturer,
        brand,
        product_type,
        unit_retail_price

),

ranked_products as (

    select
        *,
        row_number() over (
            order by unit_margin desc, part_key
        ) as unit_margin_rank,
        row_number() over (
            order by total_margin desc, part_key
        ) as total_margin_rank

    from product_margins

)

select
    part_key,
    product_name,
    manufacturer,
    brand,
    product_type,
    unit_retail_price,
    total_quantity,
    unit_margin,
    total_margin,
    unit_margin_rank,
    total_margin_rank

from ranked_products
where total_margin_rank <= 50
order by total_margin_rank
