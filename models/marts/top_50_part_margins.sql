with parts as (

    select
        p_partkey as part_key,
        p_name as part_name,
        p_retailprice as unit_retail_price
    from {{ ref('stg_tpch__part') }}

),

part_suppliers as (

    select
        ps_partkey as part_key,
        ps_availqty as available_quantity,
        ps_supplycost as unit_cost
    from {{ ref('stg_tpch__partsupp') }}

),

supplier_margins as (

    select
        parts.part_key,
        parts.part_name,
        parts.unit_retail_price,
        part_suppliers.available_quantity,
        part_suppliers.unit_cost,
        parts.unit_retail_price - part_suppliers.unit_cost as unit_margin,
        (parts.unit_retail_price - part_suppliers.unit_cost)
            * part_suppliers.available_quantity as total_margin
    from parts
    inner join part_suppliers
        on parts.part_key = part_suppliers.part_key

),

part_margins as (

    select
        part_key,
        part_name,
        unit_retail_price,
        sum(available_quantity) as total_quantity,
        sum(unit_cost * available_quantity)
            / nullif(sum(available_quantity), 0) as weighted_avg_unit_cost,
        unit_retail_price
            - (
                sum(unit_cost * available_quantity)
                / nullif(sum(available_quantity), 0)
            ) as unit_margin,
        sum(total_margin) as total_margin
    from supplier_margins
    group by 1, 2, 3

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
