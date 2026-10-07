CREATE TABLE IF NOT EXISTS bookings (
    booking_id        VARCHAR(10) PRIMARY KEY,
    passenger_name    VARCHAR(100),  passenger_phone  VARCHAR(15),
    passenger_gender  VARCHAR(10),   passenger_city   VARCHAR(60),
    route_code        VARCHAR(10),   route_from       VARCHAR(60),
    route_to          VARCHAR(60),   vehicle_plate    VARCHAR(15),
    vehicle_type      VARCHAR(20),   driver_name      VARCHAR(100),
    driver_rating     NUMERIC(3,1),  departure_date   DATE,
    departure_time    VARCHAR(10),   seat_class       VARCHAR(20),
    seats_booked      INTEGER,       fare_per_seat    NUMERIC(10,2),	
    total_fare        NUMERIC(12,2), payment_method   VARCHAR(20),
    booking_status    VARCHAR(20),   trip_rating      INTEGER
);

INSERT INTO safari_connect.bookings
SELECT
    booking_id, TRIM(passenger_name),
    NULLIF(TRIM(passenger_phone),''),
    passenger_gender, COALESCE(NULLIF(TRIM(passenger_city),''),'Unknown'),
    route_code, route_from, route_to, vehicle_plate, INITCAP(TRIM(vehicle_type)),
    TRIM(driver_name),
    NULLIF(REGEXP_REPLACE(driver_rating,'[^0-9.]','','g'),'')::NUMERIC,
    departure_date::DATE,  departure_time, seat_class,
    NULLIF(REGEXP_REPLACE(seats_booked,'[^0-9]','','g'),'')::INTEGER,
    fare_per_seat,
    total_fare,
    payment_method, booking_status,
    trip_rating
FROM safari_connect.bookings_staging;

CREATE OR REPLACE VIEW safari_connect.v_clean_trips AS 
SELECT *,
	TO_CHAR(departure_date, 'YYYY-MM') AS travel_month,
	TO_CHAR(departure_date, 'month YYYY') AS month_label,
	TO_CHAR(departure_date, 'Day') AS day_name,
	EXTRACT(MONTH FROM departure_date) AS month_num,
	EXTRACT(DOW FROM departure_date) AS day_of_week,
	(fare_per_seat * seats_booked) AS calculated_fare,
	CASE
		WHEN trip_rating BETWEEN 4 AND 5 THEN 'Satisfied'
		WHEN trip_rating = 3 THEN 'Neutral'
		WHEN trip_rating BETWEEN 1 AND 2 THEN 'Unsatisfied'
		ELSE 'No Rating'
	END AS satisfaction,
	EXTRACT(YEAR FROM departure_date) AS travel_year
FROM safari_connect.bookings
WHERE booking_status = 'Completed';

-- sanity check
SELECT COUNT(*) FROM v_clean_trips;

SELECT COUNT(*) FROM information_schema."columns" 
WHERE table_schema = 'safari_connect'
	AND table_name = 'v_clean_trips';

SELECT * FROM v_clean_trips;

-- Indexes
CREATE INDEX idx_bookings_depdate     ON bookings (departure_date);
CREATE INDEX idx_bookings_route       ON bookings (route_code);
CREATE INDEX idx_bookings_driver      ON bookings (driver_name);
CREATE INDEX idx_bookings_status      ON bookings (booking_status);
CREATE INDEX idx_bookings_payment     ON bookings (payment_method);
CREATE INDEX idx_bookings_vehicle     ON bookings (vehicle_type);
CREATE INDEX idx_bookings_passcity    ON bookings (passenger_city);

SELECT tablename, indexname FROM pg_indexes
WHERE schemaname = 'safari_connect';

