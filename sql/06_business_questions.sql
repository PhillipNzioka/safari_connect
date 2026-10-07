	select * from v_clean_trips;

/* Q1 - Route Analysis Which routes earn the most? 
 * Which are most popular? 
 * Which is most efficient per seat sold?
 */
-- Calculate total revenue
-- Calculate total bookings
-- Calculate revenue_per_seat
-- RANK() total bookings by popularity rank
-- RANK() revenue_per_set as efficiency_rank
-- RANK() total revenue as revenue_rank

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

-- revenue by vehicle type
SELECT 
	vehicle_type,
	SUM(total_fare) AS total_revenue
FROM safari_connect.v_clean_trips
GROUP BY 1
ORDER BY total_revenue DESC;

--===========================ANSWERS===================================================
-- Top Route by Revenue is RT001(Nairobi-Mombasa) with Ksh 51,600
-- Route with the least revenue is RT009(Nairobi-Machakos) with Ksh 7,300

-- Most popular city by total bookings is RT005(Nairobi-Thika) with 30 bookings
-- Least popular city by total bookings is RT009(Nairobi-Machakos) with 20 bookings

-- Most efficient per seat sold is RT001(Nairobi-Mombasa) with Ksh 1,259 per seat
-- Least efficient per seat sold is RT005(Nairobi-Thika) with Ksh 123 per seat

--=====================================================================================
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
--===========================ANSWERS==================================================
-- Top revenue generator is Isaac Korir(Matatu), generating KES 33,045 across 33 trips
-- Highest passenger satisfaction is Hassan Abdi(Minibus)- Achieves the highest average 
-- passenger trip satisfaction score of 3.9 / 5.0 (with KES 27,575 in total revenue).
-- Top driver Rating: Moses Kipchoge (Matatu) — Holds the highest driver rating at 4.8 / 5.0.
-- Balanced Performer: Hassan Abdi is noted as maintaining the best overall balance across 
-- revenue, passenger experience, and conduct metrics.

-- ===Does driver rating affect passenger satisfaction?=== No, a higher driver rating does not
-- automatically correlate with higher passenger trip satisfaction or higher revenue.
-- Key Findings:
-- Moses Kipchoge holds the top driver rating (4.8), yet his passenger trip rating is among the lowest (3.2).
-- Hassan Abdi holds a moderate driver rating (4.1), but earns the highest passenger satisfaction score (3.9).
-- Isaac Korir generates the most revenue (33,045 KES) despite a moderate driver rating (3.8) and moderate satisfaction score (3.4).
-- Operational Insight:
-- Passenger trip ratings reflect the overall trip experience — including factor levers like
-- punctuality, vehicle comfort, seat class, and route length — rather than driver conduct or personal rating alone.

-- == Which driver needs promotion?== Based on our analysis Isaac Korir deserves the promotion
-- because he generated the highest revenue(33,045), has average passenger satisfaction (3.4)  and he is top in
-- total trips driven (33).
--====================================================================================
/* Q3 - Revenue Trends How is revenue changing month by month? 
 * What are our best and worst months?
 */
-- Monthly revenue with month-over-month change 
-- month, bookings, revenue
with monthly_trend as (
	select 
		travel_month,
		count(*) as booking,
		sum(calculated_fare) as revenue_per_month
	from v_clean_trips
	group by travel_month
)
select 
	travel_month, 
	booking,
	revenue_per_month ,
	lag(revenue_per_month ) over (order by travel_month) as previous_month,
	revenue_per_month  - lag(revenue_per_month ) over (order by travel_month) as revenue_change,
	round((revenue_per_month  - lag(revenue_per_month ) over (order by travel_month))
		/nullif(lag(revenue_per_month ) over (order by travel_month),0) * 100, 1) as change_pct
from monthly_trend
order by travel_month;

-- Running total of revenue
select 
	travel_month,
	sum(calculated_fare) as monthly_total,
	sum(sum(calculated_fare)) over (order by travel_month) as running_total_revenue
from v_clean_trips
group by travel_month;

-- Best and Worst 3 months by Revenue
with monthly_trend as (
	select 
		travel_month,
		count(*) as booking,
		sum(calculated_fare) as revenue_per_month,
		rank() over (order by sum(calculated_fare) desc) as top_revenue_rank,
		rank() over (order by sum(calculated_fare) asc) as bottom_revenue_rank
	from v_clean_trips
	group by travel_month
)
select 
	travel_month,
	booking,
	revenue_per_month,
	case
		when top_revenue_rank <= 3 then 'Top'
		else 'Bottom'
	end as category	
from monthly_trend
where top_revenue_rank <= 3 or bottom_revenue_rank <= 3
order by revenue_per_month desc;

-- Revenue by Route per month (pivot)
select 
	travel_month,
	route_code,
	sum(calculated_fare) as total_revenue
from v_clean_trips
group by travel_month, route_code;

SELECT
    travel_month,
    SUM(CASE WHEN route_code = 'RT001' THEN total_fare  ELSE 0 END) AS rt001_revenue,
    SUM(CASE WHEN route_code = 'RT004' THEN total_fare ELSE 0 END) AS rt004_revenue,
    SUM(CASE WHEN route_code = 'RT002' THEN total_fare ELSE 0 END) AS rt002_revenue,
    SUM(CASE WHEN route_code IN ('RT001', 'RT004', 'RT002') THEN total_fare ELSE 0 END) AS total_top_3_revenue
FROM
    safari_connect.v_clean_trips
GROUP BY
    travel_month
ORDER BY
    travel_month;
--===========================ANSWERS==================================================

-- Top months by Revenue
		-- Oct 2024 generated KES 23,680
		-- July 2024 generated KES 22,855
		-- Nov 2024 generated KES 20,270
-- Worst months by Revenue
		-- Jan 2025 generated KES 1,685
		-- Aug 2024 generated KES 13,400
		-- Feb 2024 generated KES 15,640

--====================================================================================
/* Q4 - Passenger Insights Where do passengers come from?
 * What seat class do they prefer? 
 * Are they satisfied?
 */
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

-- Gender split and seat class preference
select 
	passenger_gender,
	count(*) as total_bookings,
	sum(calculated_fare) as total_revenue,
	sum(case when seat_class = 'Economy' then 1 else 0 end) as economy_bookings,
	sum(case when seat_class = 'Economy' then calculated_fare  else 0 end) as economy_revenue,
	sum(case when seat_class = 'Business' then 1 else 0 end) as business_bookings,
	sum(case when seat_class = 'Business' then calculated_fare  else 0 end) as business_revenue
from v_clean_trips
group by passenger_gender;

-- Satisfaction breakdown
select 
	satisfaction,
 	count(*) as satisfaction_count,
 	round(100 * count(*) / sum(count(*)) over (), 1) as pct_of_total
from v_clean_trips
group by satisfaction 
order by satisfaction_count desc;

-- Passenger quartiles by spend (NTILE)
with passenger_totals as (
	select 
		passenger_name,
		sum(calculated_fare) as total_spend,
		ntile(4) over (order by sum(calculated_fare) asc) as passenger_quartile
	from v_clean_trips
	group by passenger_name 
)
select
	passenger_name,
	total_spend,
	passenger_quartile,
	case 
		when passenger_quartile = 4 then 'Top Spender'
	end as quartile_label	
from passenger_totals
order by total_spend desc;


--===========================ANSWERS==================================================
-- Top Cities
		-- Nairobi is the top with 113 bookings generating a revenue of KES 112,000
-- 79.4%(201) of the bookings choose Economy class and 20.6%(52) choose Business class.

-- In gender the female generated the highest revenue(KES 120,885) compared to the 
-- male(KES 106,925), economy class was best preferred when it came to customer seat bookings.

-- 46.2%(117) of the passengers are satisfied, 28.9%(73)  are neutral and 19.4%(49) 
-- are unsatisfied. They can work on getting their customers satisfaction to atleast 50%.

--====================================================================================
/* Q5 - Cancellations What is the cancellation rate per route? 
 * How much revenue did cancellations cost us?
 */
-- Overall Status Breakdown
select 
	booking_status,
	count(*) as bookings
from safari_connect.bookings_staging
group by booking_status 
order by bookings desc;


-- Cancellation Rate by route
select
	route_code,
	concat(route_from, ' - ', route_to) as route_name,
	count(*) as total_bookings,
	sum(case when booking_status = 'Completed' then 1 else 0 end) as completed,
	sum(case when booking_status = 'Cancelled' then 1 else 0 end) as cancelled,
	sum(case when booking_status = 'No Show' then 1 else 0 end) as no_show,
	round(sum(case when booking_status in ('Cancelled','No Show') then 1 else 0 end) * 100.0 / count(*), 1) as cancel_rate_pct
from safari_connect.bookings_staging
group by route_code, route_name
order by cancel_rate_pct desc;

-- Revenue lost from cancellations and no-shows
select 
	booking_status,
	count(*) as bookings,
	sum(total_fare) as revenue_lost
from safari_connect.bookings_staging
where booking_status in ('Cancelled','No Show')
group by booking_status;

-- Revenue lost per route
select
    route_code,
    concat(route_from, ' - ', route_to) as route_name,
    sum(case when booking_status = 'Cancelled' then total_fare else 0 end) as cancelled_revenue_lost,
    sum(case when booking_status = 'No Show' then total_fare else 0 end) as no_show_revenue_lost,
    sum(case when booking_status in ('Cancelled','No Show') then total_fare else 0 end) as total_revenue_lost
from safari_connect.bookings_staging 
group by route_code, route_from, route_to
order by total_revenue_lost desc;

--===========================ANSWERS==================================================

-- Worst route for cancellations is Mombasa-Malindi at 18.5%
-- Least route for cancellations is Nairobi-Eldoret at 3.6%

-- Total Revenue lost is KES 32,150.
	-- Cancelled is KES 24,805
	-- No Show is KES 7,345

-- RT001(Nairobi-Mombasa) has the highest revenue lost at KES 10,800 but was not the worst route 
-- for cancellation. This is because its seat is expensive.

-- Policy Recommendation
-- No refund for cancellation and no show on travel day.
-- 50% refund for cancellations two days before departure.
--====================================================================================
/* Q6 - Operational Patterns What are our busiest days and times?
 * When should we add more vehicles?
 */
--Revenue by day of week
select 	
	day_of_week,
	day_name,
	count(*) as total_bookings,
	sum(calculated_fare) as total_revenue
from v_clean_trips
group by day_of_week, day_name
order by total_revenue desc;

-- Busiest departure times
select 
	departure_time,	
	count(*) as total_bookings,
	sum(calculated_fare) as total_revenue
from v_clean_trips
group by departure_time
order by total_bookings desc;

-- Seat utilisation by vehicle type
select 	
	vehicle_type,
	round(avg(seats_booked),0) as avg_seats_booked,
	case 
		when avg(seats_booked) > 3 then 'High Load'
		when avg(seats_booked) >= 2 then 'Medium Load'
		else 'Low Load'
	end as load_label
from v_clean_trips
group by vehicle_type
order by avg_seats_booked desc;

--===========================ANSWERS==================================================
-- Monday generates the highest revenue (KES 47,350) and Wednesday more bookings were made
-- compared to other days (52).
-- Sunday generates the lowest revenue(KES 8,835) and 11 bookings.

-- The busiest departure time is 09:00 with 25 bookings and 06:00 with 24 bookings.
-- 16:00 - 17:30 bookings are slow with 18 bookings.

-- 19:00 generates the highest revenue(KES 22,240)
-- 13:00 generates the lowest revenue(KES 12,045)

-- All vehicle_types have low load(avg 2 seats booked)

-- Recommendation
	--1. from the analysis  at 09:00 there is more bookings made,
	-- to increase on vehicle load more vehicles should operate from 06:00 to 09:00.


