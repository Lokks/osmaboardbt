
-- changesets_filtered_by_month_host

select 

year(closed_at) as cs_year,
month(closed_at) as cs_month,
{{ host_name_unification('host') }} as host,
count(*) as cs_cnt

from {{ ref('changesets_filtered_raw') }} 
group by 1, 2, 3
order by 4 desc -- debug purpose only
