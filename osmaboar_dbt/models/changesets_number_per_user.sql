-- changesets_number_per_user
{{ config(materialized='table') }}

select 
id,
uid,
row_number() over (partition by uid order by closed_at asc) as cs_number_per_user

from {{ ref('changesets_raw_cleaned') }} 
where uid > 0
