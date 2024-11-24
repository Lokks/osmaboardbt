{% macro created_by_name_unification(column_name, default_value='others') %}
case 
    when {{ column_name }} like 'id%' then 'iD'
    when {{ column_name }} like 'streetcomplete%' then 'StreetComplete'
    when {{ column_name }} like 'josm%' then 'JOSM'
    when {{ column_name }} like 'vespucci%' then 'Vespucci'
    when {{ column_name }} like 'level0%' then 'Level0'
    when {{ column_name }} like 'every door%' then 'Every_Door'
    when {{ column_name }} like 'osmapi%' then 'osmapi'
    when {{ column_name }} = 'osm.org tags editor' then 'Osm_Org_Tags_Editor'
    when {{ column_name }} like 'rapid%' then 'Rapid'
    when {{ column_name }} like 'go map%' then 'Go_Map'
    when {{ column_name }} like '%wheelmap.org%' then 'wheelmap_org'
    when {{ column_name }} like 'map bulder%' then 'Map_bulder'
    when {{ column_name }} like 'maproulette%' then 'MapRoulette'
    when {{ column_name }} like 'votre solution de%' then 'Votre_Solution'
    when {{ column_name }} like '%map.osm.wikidata.link%' then 'Link_Wikidata_OSM_tool'
    when {{ column_name }} like 'maps.me%' then 'MAPS_ME'
    when {{ column_name }} like 'osmand%' then 'OsmAnd'
    when {{ column_name }} like 'potlatch%' then 'Potlatch'
    when {{ column_name }} like 'osmμapi.py%' then 'OSM_api_py'
    when {{ column_name }} like 'organic maps%' then 'Organic_Maps'
    when {{ column_name }} like 'b-jazz%' or {{ column_name }} like 'https_all_the_things%' then 'b-jazz'
    when {{ column_name }} like 'osm-revert%' then 'osm_revert'
    when {{ column_name }} like 'openstop%' then 'OpenStop'
    when {{ column_name }} like 'open mapper%' then 'Open_Mapper'
    when {{ column_name }} like 'onwheels%' then 'OnWheels'
    when {{ column_name }} like 'osmybiz%' then 'OSMyBiz'
    

    else '{{ default_value }}'
end
{% endmacro %}
