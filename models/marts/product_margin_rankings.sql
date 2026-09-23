with parts as (

    select * from {{ ref('stg_tpch__part') }}

),

part_suppliers as (

    select * from {{ ref('stg_tpch__partsupp') }}

),

part_costs as (

    select
        ps_partkey as part_key,
        sum(ps_availqty) as total_quantity,
        (
            sum(ps_supplycost * ps_availqty)
            / nullif(sum(ps_availqty), 0)
        )::decimal(18, 4) as unit_cost
    from part_suppliers
    group by ps_partkey

),

product_margins as (

    select
        parts.p_partkey as part_key,
        parts.p_name as part_name,
        parts.p_mfgr as manufacturer,
        parts.p_brand as brand,
        parts.p_type as part_type,
        parts.p_retailprice::decimal(18, 4) as unit_retail_price,
        part_costs.unit_cost,
        part_costs.total_quantity,
        (
            parts.p_retailprice - part_costs.unit_cost
        )::decimal(18, 4) as unit_margin,
        (
            (parts.p_retailprice - part_costs.unit_cost)
            * part_costs.total_quantity
        )::decimal(18, 4) as total_margin
    from parts
    inner join part_costs
        on parts.p_partkey = part_costs.part_key

),

ranked as (

    select
        *,
        row_number() over (
            order by unit_margin desc nulls last, part_key
        ) as unit_margin_rank,
        row_number() over (
            order by total_margin desc nulls last, part_key
        ) as total_margin_rank
    from product_margins

)

select *
from ranked
where unit_margin_rank <= 50
    or total_margin_rank <= 50
order by total_margin_rank, unit_margin_rank
