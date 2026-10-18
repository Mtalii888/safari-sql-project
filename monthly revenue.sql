SET search_path TO safaari_connect;

-- -- ------------------------------------------------------------------------------------------------------------------------
--												 Revenue Trends Analysis
-- ===========================================================================================================================

-- 3A - Monthly revenue with month-over-month change (CTE + LAG)

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

--3B - Running total of revenue
--Show each month with its revenue and a cumulative running total from January onwards.
select 
		date_trunc('month', departure_date) ::date as months,
		SUM(total_fare) as revenue,
		SUM(SUM(total_fare)) OVER (ORDER BY date_trunc('month', departure_date))as cummulative_revenue
from safaari_connect.vw_clean_trips 
where booking_status = 'Completed'
group by date_trunc('month', departure_date)
order by months;

--3C - Best and worst 3 months
--Using a CTE for monthly revenue, show the top 3 months and the bottom 3 months by revenue. Use RANK().

with monthly_revenue as (
    -- step 1: total revenue per calendar month
    select
        date_trunc('month', departure_date) ::date as months, 
        sum(total_fare)   as revenue
    from safari_connect.v_clean_trips
    where booking_status = 'Completed'
    group by date_trunc('month', departure_date)
),
ranked_revenue as (
select  months, 
		revenue,
		rank() over (order by revenue desc) as top_rank,
		rank() over (order by revenue asc) as bottom_rank
from monthly_revenue
) 
select  months,
		revenue,
		case 
			when top_rank <= 3 then 'Top 3'
			when bottom_rank <= 3 then 'Bottom 3'
		end as performance_group
from ranked_revenue
where top_rank <= 3 or bottom_rank <= 3
order by revenue desc ;

--3D - Revenue by route per month (pivot)
--Show one row per month with separate columns for the top 3 routes (RT001, RT002, RT003) using CASE WHEN + SUM.

select
    date_trunc('month', departure_date) ::date as reporting_month,
    -- Pivot column for Route RT001
    case when route_code = 'RT001' then sum(total_fare) else 0 end as route_rt001_revenue,
    -- Pivot column for Route RT002
    case when route_code = 'RT002' then sum(total_fare) else 0 end as route_rt002_revenue,
    -- Pivot column for Route RT003
    case when route_code = 'RT003' then sum(total_fare) else 0 end as route_rt003_revenue,
    -- Total monthly revenue across all routes for reference
    sum(total_fare) as total_monthly_revenue
from safaari_connect.vw_clean_trips
where booking_status = 'Completed'
partition by date_trunc('month', departure_date)
order by reporting_month;