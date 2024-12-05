-- poland_internal
{{ config(materialized='table') }}

select
    cast(properties->>'@changeset' as bigint) as changeset,
    properties->>'@type' as osm_type,
    ST_GeomFromGeoJSON(geom_geojson) as geom,
    properties as tags  

from poland_internal.poland_internal_raw
