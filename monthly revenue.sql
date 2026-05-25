set search_path to safaari_connect;
select * from vw_clean_trips;

with v_monthly_revenue  as (
select  month(departure_date::date),
         sum(total_fare) as total_revenue,
         to_char(departure_date, 'Month') as month_name
         from vw_clean_trips  order by month(departure_date))
select departure_date,
       month_name,
       total_revenue,
       sum (total_revenue)over( partition by month_name order by month_name) as cumulative_revenue 
       from v_monthly_revenue
order by departure_date;
         