
-- changesets_filtered_by_month_app
{{ config(materialized='table') }}

select 

year(closed_at) as cs_year,
month(closed_at) as cs_month,
{{ created_by_name_unification('created_by', default_value='others') }} as created_by,
count(*) as cs_cnt,
sum(case when cs_number_for_user = 1 then 1 else 0 end) as cs_cnt_first_cs

from {{ ref('changesets_filtered_raw') }} 
group by 1, 2, 3
order by 4 desc -- debug purpose only
