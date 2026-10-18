set search_path to safaari_connect;
select * from vw_clean_trips;
select * from bookings_staging;
--5A - Overall status breakdown
select booking_status,
       count(*) as total_bookings,
       sum(total_fare) as revenue,
       avg(trip_rating) as avg_rating
from bookings_staging
group by booking_status;
--Show: route_code, route, total_bookings, completed, cancelled, no_show, cancellation_rate_pct.
with cancellation_analysis as (select route_code,
                                      route_from,
                                      route_to,
                                      count (*) as total_bookings,
                                      sum(case 
                                      	when booking_status ='Completed' then 1 else 0
                                      end ) as completed,
                                      sum(case 
                                      	when booking_status ='Cancelled' then 1 else 0
                                      end) as cancelled,
                                      sum(case 
                                      	when booking_status ='No show' then 1 else 0
                                      end) as no_show
                                      from bookings_staging
                                      group by route_code,route_from,route_to
                                     )
select * ,round(cancelled *100/(cancelled + completed + no_show),2)as cancellation_rate_pct from cancellation_analysis;


--5C - Revenue lost from cancellations and no-shows
select sum(total_fare)
from bookings_staging
where booking_status in ('Cancelled','No show');