with parts as (

    select * from {{ ref('stg_tpch__part') }}

),

part_suppliers as (

    select * from {{ ref('stg_tpch__partsupp') }}

),

final as (

    select
        part_suppliers.ps_partkey,
        part_suppliers.ps_suppkey,
        part_suppliers.ps_availqty,
        part_suppliers.ps_supplycost,
        part_suppliers.ps_comment,
        parts.p_name,
        parts.p_mfgr,
        parts.p_brand,
        parts.p_type,
        parts.p_size,
        parts.p_container,
        parts.p_retailprice,
        parts.p_comment
    from part_suppliers
    inner join parts
        on part_suppliers.ps_partkey = parts.p_partkey

)

select * from final
