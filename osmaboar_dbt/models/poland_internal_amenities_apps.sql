-- poland_internal_amenities_apps

{{ config(materialized='table') }}

select
    pi.changeset_id,
    pi.osm_type,
    {{ created_by_name_unification('created_by', default_value='others') }} as created_by,
    case 
        when pi.tags->>'@amenity' = 'shop' then true
    else false 
    end as is_shop,
    case
        when json_extract(pi.tags, '$.opening_hours') is not null then true
    else false 
    end as has_opening_hours

from {{ ref('poland_internal') }} as pi
left join {{ ref('changesets_raw') }} as cs 
    on pi.changeset = cs.id

where json_extract(pi.tags, '$.amenity') is not null
