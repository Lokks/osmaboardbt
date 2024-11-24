-- changesets_filtered_raw
-- {{ config(materialized='table') }}

select
    cast(id as bigint) as id,
    cast (created_at as timestamptz) as created_at,
    --cast (closed_at as timestamptz) as closed_at,
    cast (uid as bigint) as uid,
    user,
    cast (num_changes as int) as num_changes,
    cast(min_lat as double) as min_lat,
    cast(min_lon as double) as min_lon,
    cast(max_lat as double) as max_lat, 
    cast(max_lon as double) as max_lon,
    lower(created_by) as created_by,
    lower(imagery_used) as imagery_used,
    case 
        when host like 'http://' then 'http_host'
        else replace(replace(lower(host), 'https://', ''), 'www.', '')
    end as host,
    lower(hashtags) as hashtags,
    row_number() over (partition by user order by created_at asc) as cs_number_per_user  -- change to closed

from '../data/mid/osmium/changesets_filtered.parquet'