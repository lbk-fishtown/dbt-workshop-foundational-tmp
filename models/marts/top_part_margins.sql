{{ config(materialized='table') }}

with part_margins as (

    select * from {{ ref('part_margins') }}

)

select *
from part_margins
where total_margin_rank <= 50
order by total_margin_rank
