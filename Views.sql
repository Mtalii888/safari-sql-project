set search_path to safaari_connect;
create or replace view v_route_performance as
with v_route_perfomance as (
                            select route_code,
                                   route_from,
                                   route_to,
                                   count(booking_id)  as total_bookings,
                                   sum(seats_booked) as total_seats,
                                   sum(total_fare) as total_revenue,
                                   round(avg(total_fare),2) as avg_fare,
                                   round(avg(trip_rating),2) as avg_trip_rating
                            from vw_clean_trips group by route_code,
                                                         route_from,
                                                         route_to 
                                                 order by total_revenue desc)
select route_code,
       route_from,
       route_to,
       total_bookings,
       total_seats,
       total_revenue,
       avg_fare,
       avg_trip_rating
from v_route_perfomance;
select * from v_route_performance;

create or replace view v_driver_performance as
with v_driver_performance as (
select driver_name,
       vehicle_type,
       round(avg(driver_rating):: numeric,2) as avg_driver_rating,
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
select * from v_driver_performance;

create or replace view v_monthly_revenue as 
with monthly_revenue as (
    -- step 1: total revenue per calendar month
    select
        date_trunc('month', departure_date) ::date as month_start, 
        sum(total_fare)   as revenue
    from safaari_connect.vw_clean_trips
    where booking_status = 'Completed'
    group by date_trunc('month', departure_date)
)
select
    month_start,
    revenue,
    -- previous month's revenue (null for the first month by default)
    lag(revenue) over (order by month_start) as prior_month_revenue,
    -- absolute change vs previous month (KES)
    revenue - lag(revenue) over (order by month_start) as revenue_variance,
    -- percentage change vs previous month
    round(
        100.0 * (revenue - lag(revenue) over (order by month_start))
        / nullif(lag(revenue) over (order by month_start), 0),
        2
    ) as revenue_growth_rate
from monthly_revenue
order by month_start;
select * from v_monthly_revenue;

create or replace view v_cancellation_analysis as
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
select * ,round(cancelled *100/(cancelled + completed + no_show),2)as cancellation_rate_pct
from cancellation_analysis;
select * from v_cancellation_analysis;

create or replace view v_passenger_insights as 
with v_cancellation_analysis as (
select passenger_city,
       count(booking_id) as total_bookings,
       sum(seats_booked) as total_seats,
       sum(total_fare) as total_revenue,
       avg(total_fare) as avg_fare
from vw_clean_trips
group by passenger_city)
select * from v_cancellation_analysis 
where total_bookings > 3
order by total_bookings;
select * from v_passenger_insights;