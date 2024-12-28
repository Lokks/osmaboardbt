-- changesets_raw_cleaned
{{ config(materialized='table') }}

select 
    id,
    closed_at,
    created_by,
    uid,
    host
from (
      select
        id,
        closed_at,
        created_by,
        uid,
        host,
        row_number() over (
            partition by id
            order by closed_at DESC
            ) as rn
      from {{ ref('changesets_raw') }}
    ) a
where rn = 1