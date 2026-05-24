set search_path to safaari_connect;

select * from vw_clean_trips;
--cte for driver perfomance
with v_driver_performance as (
select driver_name,
       vehicle_type,
       round(avg(driver_rating),2) as avg_driver_rating,
       count(*) as total_trips,
       sum(seats_booked) as total_seats_carried,
       sum(total_fare) as total_revenue,
       round(avg(trip_rating),2) as avg_trip_rating 
       from vw_clean_trips
       group by driver_name,vehicle_type order by  total_revenue desc)    
 select driver_name,
        total_revenue,
        rank() over(partition by vehicle_type order by total_revenue desc) as rank,
        vehicle_type
        from v_driver_performance;
with v_driver_performance as (
select driver_name,
       vehicle_type,
       round(avg(driver_rating::numeric),2) as avg_driver_rating,
       count(*) as total_trips,
       sum(seats_booked) as total_seats_carried,
       sum(total_fare) as total_revenue,
       round(avg(trip_rating::numeric),2) as avg_trip_rating 
       from vw_clean_trips
       group by driver_name,vehicle_type order by  total_revenue desc)
select driver_name,
       vehicle_type,
       avg_driver_rating,
       avg_trip_rating
       from v_driver_performance order by  avg_driver_rating desc;

      