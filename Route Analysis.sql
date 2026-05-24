set search_path to safaari_connect;

select * from vw_clean_trips;
--cte for route perfomance question 1a
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
--question 1b
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
       total_revenue,
       total_seats,
       sum(total_revenue / total_seats)  as revenue_per_seat
from v_route_perfomance 
group by route_code, route_from, route_to,total_revenue,total_seats order by total_revenue desc;
--question 1c
with v_route_perfomance as (
                            select route_code,
                                   route_from,
                                   route_to,
                                   count(booking_id)  as total_bookings,
                                   sum(seats_booked) as total_seats,
                                   sum(total_fare) as total_revenue,
                                   avg(total_fare) as avg_fare,
                                   avg(trip_rating) as avg_trip_rating
                            from vw_clean_trips group by route_code,
                                                         route_from,
                                                         route_to 
                                                 order by total_revenue desc)
select  route_code,
        route_from,
        route_to,
        total_revenue,
        rank() over(order by total_revenue desc) as rank,
        round((total_revenue * 100) / sum(total_revenue) over(),2 )as revenue_percentage
        from v_route_perfomance
        group by route_code,
        route_from,
        route_to,
        total_revenue ;
--question 1d cte for vehicle perfomance
with v_vehicle_perfomance as (
                            select vehicle_type,
                                   count(booking_id)  as total_bookings,
                                   sum(seats_booked) as total_seats,
                                   sum(total_fare) as total_revenue,
                                   avg(total_fare) as avg_fare,
                                   round(avg(trip_rating),2) as avg_trip_rating
                            from vw_clean_trips group by vehicle_type)
select vehicle_type,
       total_bookings,
       total_revenue,
       avg_trip_rating
from v_vehicle_perfomance order by total_revenue desc;