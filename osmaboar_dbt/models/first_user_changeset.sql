-- first_user_changeset
{{ config(materialized='table') }}

select 

uid, 
min_by(id, closed_at) as first_cs_id 

from {{ ref('changesets_raw_cleaned') }} 
where uid > 0
group by uid
