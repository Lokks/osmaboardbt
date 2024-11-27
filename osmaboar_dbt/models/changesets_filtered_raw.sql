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
    lower(tags['created_by'][1]) as created_by,
    lower(tags['imagery_used'][1]) as imagery_used,
    case 
        when tags['host'][1] like 'http:%' then 'http_host'
        else replace(replace(lower(tags['host'][1]), 'https://', ''), 'www.', '')
    end as host,
    lower(tags['hashtags'][1]) as hashtags,
    row_number() over (partition by user order by closed_at asc) as cs_number_for_user

from parquet_scan('../data/out/parquet/changesets*.parquet')