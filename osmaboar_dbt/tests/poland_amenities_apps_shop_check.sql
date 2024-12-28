-- check if we have at least one shop in amenities table
-- poland_amenities_apps_shop_check

select 1
where not exists
(
    select 1
    from {{ ref('poland_internal_amenities_apps') }}
    where is_shop = 'true'
)
