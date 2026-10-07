CREATE SCHEMA IF NOT EXISTS safari_connect;

SET search_path TO safari_connect;

CREATE TABLE IF NOT EXISTS safari_connect.safari_connect_dirty(
	booking_id            TEXT,
	passenger_name        TEXT,
	passenger_phone       TEXT,
	passenger_gender      TEXT,
	passenger_city        TEXT,
	route_code            TEXT,
	route_from            TEXT,
	route_to              TEXT,
	vehicle_plate         TEXT,
	vehicle_type          TEXT,
	driver_name           TEXT,
	driver_rating         TEXT,
	departure_date        TEXT,
	departure_time        TEXT,
	seat_class            TEXT,
	seats_booked          TEXT,
	fare_per_seat         TEXT,
	total_fare            TEXT,
	payment_method        TEXT,
	booking_status        TEXT,
	trip_rating           TEXT
)

-- Sanity Check
SELECT COUNT(*) AS row_num FROM safari_connect.safari_connect_dirty;

SELECT COUNT(*) FROM information_schema."columns"
WHERE table_schema = 'safari_connect'
	AND table_name = 'safari_connect_dirty';