-- changesets_filtered_raw
{{ config(materialized='table') }}

select
    id,
    created_at,
    closed_at,
    uid,
    user,
    num_changes,
    min_lat,
    min_lon,
    max_lat, 
    max_lon,
    lower(created_by) as created_by,
    lower(imagery_used) as imagery_used,
    case 
        when host like 'http://' then 'http_host'
        else replace(replace(lower(host), 'https://', ''), 'www.', '')
    end as host,
    lower(hashtags) as hashtags,
    row_number() over (partition by user order by closed_at asc) as cs_number_for_user

from parquet_scan('../data/out/parquet/changesets*.parquet')