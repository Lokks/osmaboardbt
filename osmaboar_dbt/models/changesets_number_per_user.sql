-- changesets_number_per_user
{{ config(materialized='table') }}

select 

id,
row_number() over (partition by uid order by filename asc, closed_at asc) as cs_number_per_user

from {{ ref('changesets_raw') }} 