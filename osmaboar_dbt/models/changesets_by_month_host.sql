
-- changesets_by_month_host
{{ config(materialized='table') }}

select 

date_trunc('month', closed_at) as cs_month,
{{ host_name_unification('host') }} as host,
count(*) as cs_count

from {{ ref('changesets_raw') }} 
group by 1, 2