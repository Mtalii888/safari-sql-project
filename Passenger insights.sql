set search_path to safaari_connect;
select * from vw_clean_trips;

--Show: passenger_city, total_bookings, total_seats, total_revenue, avg_fare.
-- Order by total_bookings descending. Only include cities with 3+ bookings
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

--Show bookings and revenue broken down by passenger_gender and seat_class.
-- Use a CASE WHEN pivot to show Economy and Business as separate columns.
select passenger_gender,
       count(booking_id ) as bookings,
       sum(case when seat_class = 'Economy' then total_fare end ) as economy_revenue,
       sum(case when seat_class = 'Business' then total_fare end) as business_revenue
       from vw_clean_trips
       group by passenger_gender;
       
--Using a CTE, count how many trips fall into each satisfaction category (Satisfied / Neutral / Unsatisfied / No Rating).
-- Show count and percentage of total completed trips.
--step1: Alter view and add a new column of the satisfaction category
create or replace view vw_clean_trips as
select *,case 
	when trip_rating in (1,2) then 'unsatisfied'
	when trip_rating = 3 then 'neutral'
	when trip_rating in (4,5) then 'satisfied'
	when trip_rating is null then 'No rating'
	else 'other'
end as satisfaction_category
from bookings_staging
where booking_status = 'Completed';
--cte for total count
with v_satisfaction_category as (select satisfaction_category,
                                       count(*) as total_count
                                       from vw_clean_trips
                                       group by satisfaction_category),
v_satisfaction_percentage as (select satisfaction_category,
                                     total_count,
                                     round((total_count * 100.0/sum(total_count) over()):: numeric,2 )as percentage
                                       from v_satisfaction_category
                                     )
select satisfaction_category,
        total_count,
        percentage
from v_satisfaction_percentage;



--Using a CTE for total spend per passenger, divide passengers into 4 quartiles using NTILE(4).
--Show: passenger_name, total_spent, quartile. Label quartile 4 as 'Top Spender'.

with total_spend_passenger as (select passenger_name,
                                      sum(total_fare) as total_spent 
from vw_clean_trips
group by passenger_name),
passenger_quartile as (select passenger_name,
                              total_spent,
                              ntile(4) over(order by Total_spent) as quartile
from total_spend_passenger)
select passenger_name,
       total_spent,
       case 
       	when quartile = 4 then 'Top spender'
       	else quartile::text
       end as quartile
          from passenger_quartile;

