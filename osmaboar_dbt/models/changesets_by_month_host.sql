
-- changesets_by_month_host
{{ config(materialized='table') }}

select 

year(closed_at) as cs_year,
month(closed_at) as cs_month,
{{ host_name_unification('host') }} as host,
count(*) as cs_count

from {{ ref('changesets_raw') }} 
group by 1, 2, 3
order by 4 desc -- debug purpose only
