CREATE OR REPLACE VIEW v_route_performance AS
-- paste your 1A query here

with route_performance as (
		select
			route_code,
			concat(route_from,' - ',route_to) as route_name,
			sum(calculated_fare) as total_revenue,
			count(booking_id) as total_bookings,
			sum(seats_booked) as total_seats_booked,
			round(sum(calculated_fare) / sum(seats_booked),0) as revenue_per_seat
		from v_clean_trips
		group by route_code, route_name 
)
select 
	route_code, 
	route_name,
	total_revenue, 
	total_bookings, 
	revenue_per_seat,
	rank() over (order by total_revenue desc) as revenue_rank,
	rank() over (order by total_bookings desc) as popularity_rank,
	rank() over (order by revenue_per_seat desc) as efficiency_rank
from route_performance
order by total_revenue desc;

--====================================================================================
-- View 2: Driver performance
CREATE OR REPLACE VIEW v_driver_performance AS
-- paste your 2A query here

/* Q2 - Driver Performance Who are the best drivers? 
 * Does driver rating affect passenger satisfaction?
 */
with driver_stats as (
	select 
		driver_name,
		driver_rating,
		vehicle_type,
		count(booking_id) as trips_driven,
		sum(calculated_fare) as total_revenue,
		round(avg(trip_rating),1) as avg_passenger_satisfaction
	from v_clean_trips
	group by driver_name,driver_rating,vehicle_type 
)
select 
	driver_name, 
	driver_rating,
	trips_driven,
	total_revenue,
	avg_passenger_satisfaction,
	vehicle_type,
	rank() over (order by total_revenue desc) as revenue_rank,
	rank() over (order by avg_passenger_satisfaction desc) as satisfaction_rank
from driver_stats 
order by total_revenue desc;

--====================================================================================
-- View 3: Monthly revenue trend
CREATE OR REPLACE VIEW v_monthly_revenue AS
-- paste your 3A query (the CTE) here

with monthly_trend as (
	select 
		travel_month,
		month_num,
		count(*) as booking,
		sum(calculated_fare) as revenue_per_month
	from v_clean_trips
	group by travel_month, month_num
)
select 
	travel_month, 
	booking,
	revenue_per_month ,
	lag(revenue_per_month ) over (order by travel_month) as previous_month,
	revenue_per_month  - lag(revenue_per_month ) over (order by travel_month) as revenue_change,
	round((revenue_per_month  - lag(revenue_per_month ) over (order by travel_month))
		/nullif(lag(revenue_per_month ) over (order by travel_month),0) * 100, 1) as change_pct,
	month_num			
from monthly_trend
order by travel_month;

--====================================================================================
-- View 4: Cancellation analysis
CREATE OR REPLACE VIEW v_cancellation_analysis AS
-- paste your 5B query here

select
	route_code,
	concat(route_from, ' - ', route_to) as route_name,
	count(*) as total_bookings,
	sum(case when booking_status = 'Completed' then 1 else 0 end) as completed,
	sum(case when booking_status = 'Cancelled' then 1 else 0 end) as cancelled,
	sum(case when booking_status = 'No Show' then 1 else 0 end) as no_show,
	round(sum(case when booking_status in ('Cancelled','No Show')
		then 1 else 0 end) * 100.0 / count(*), 1) as cancel_rate_pct
from safari_connect.bookings_staging
group by route_code, route_name
order by cancel_rate_pct desc;


-- View 5: Passenger city insights	
CREATE OR REPLACE VIEW v_passenger_insights AS
-- paste your 4A query here

-- Passengers top cities
select 
	passenger_city,
	count(*) as total_bookings,
	sum(seats_booked) as total_seats,
	sum(calculated_fare) as total_revenue,
	round(avg(calculated_fare), 0) as avg_fare
from v_clean_trips
group by passenger_city 
having count(*) > 3
order by total_bookings desc;


-- View 6:
-- KPIs
CREATE OR REPLACE VIEW v_kpis AS
	SELECT 
		SUM(total_fare) AS total_revenue,
		COUNT(*) AS total_bookings,
		SUM(seats_booked) AS total_seats_booked,
		ROUND(AVG(trip_rating), 1) AS avg_trip_rating,
		ROUND(AVG(driver_rating), 1) AS avg_driver_rating
	FROM safari_connect.bookings;	
		
