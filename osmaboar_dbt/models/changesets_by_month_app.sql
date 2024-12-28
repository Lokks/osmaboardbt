
-- changesets_by_month_app
{{ config(materialized='table') }}

select 

date_trunc('month', r.closed_at) as cs_month,
{{ created_by_name_unification('created_by', default_value='others') }} as created_by,
count(r.id) as cs_count,
count(f.first_cs_id) as cs_count_first_cs

from {{ ref('changesets_raw_cleaned') }} as r
left join {{ ref('first_user_changeset') }} as f
on r.id = f.first_cs_id
group by 1, 2
