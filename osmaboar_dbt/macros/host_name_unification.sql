{% macro host_name_unification(column_name) %}
case 
    when {{ column_name }} = '' or {{ column_name }} is null then 'no_data'
    when {{ column_name }} = 'http_host' then 'http_host'

    -- maybe later
    -- when {{ column_name }} like 'openstreetmap.org%%' then 'openstreetmap_org'
    -- when {{ column_name }} like 'openstreetmap.us%%' then 'openstreetmap_us'
    -- when {{ column_name }} like 'openstreetmap.ie%%' then 'openstreetmap_ie'
    -- when {{ column_name }} like 'rapideditor.org%' then 'rapideditor_org'
    -- when {{ column_name }} like 'lyft.com%' then 'lyft_com'
    -- when {{ column_name }} like 'bing.com/mapbuilder%' then 'bing_mapbuilder'
    -- when {{ column_name }} like 'hotosm.org%' then 'hotosm_org'
    -- when {{ column_name }} like 'mapbox.com%' then 'mapbox_com'
    -- when {{ column_name }} like 'teachosm.org%' then 'teachosm_org'
    -- when {{ column_name }} like 'kyle.kiwi%' then 'kyle_kiwi'
   

    else split_part( {{ column_name }}, '/', 1)
end
{% endmacro %}
