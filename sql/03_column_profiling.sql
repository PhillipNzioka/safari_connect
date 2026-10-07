-- booking_id
SELECT booking_id FROM safari_connect.safari_connect_dirty;

-- passenger_name
-- standardize passenger_name - TRIM() then INITCAP()
SELECT DISTINCT 
	passenger_name AS raw_name,
	TRIM(INITCAP(passenger_name)) AS passenger_name
FROM safari_connect.bookings_raw;

-- passenger_phone

SELECT DISTINCT  
    passenger_phone AS raw_phone,
    CASE 
	    -- Handle NULLS
	    WHEN passenger_phone IS NULL 
	    		OR passenger_phone = '' THEN NULL
        ELSE 
            CASE 
                -- Replace leading '254' prefix with '0'
                WHEN REGEXP_REPLACE(passenger_phone, '[^0-9]', '', 'g') LIKE '254%' THEN 
                    '0' || SUBSTRING(REGEXP_REPLACE(passenger_phone, '[^0-9]', '', 'g') FROM 4)   
                -- Prepend '0' if 9 digits remaining (e.g., '712345678')
                WHEN LENGTH(REGEXP_REPLACE(passenger_phone, '[^0-9]', '', 'g')) = 9 THEN 
                    '0' || REGEXP_REPLACE(passenger_phone, '[^0-9]', '', 'g')
                -- Standard local format ('0712345678')
                ELSE 
                    REGEXP_REPLACE(passenger_phone, '[^0-9]', '', 'g')
            END
    END AS passenger_phone
FROM safari_connect.bookings_raw;	

-- passenger_gender
-- standardize gender to Male and Female
SELECT DISTINCT 
	 passenger_gender AS raw_gender,
	 CASE 
	 	WHEN INITCAP(passenger_gender) IN ('F', 'Female') THEN 'Female'
	 	WHEN INITCAP(passenger_gender) IN ('M', 'Male') THEN 'Male'
	 END AS passenger_gender
FROM safari_connect.bookings_raw;

-- passenger_city
SELECT DISTINCT INITCAP(passenger_city) FROM safari_connect.bookings_raw;

-- route_code
SELECT DISTINCT route_code FROM safari_connect.bookings_raw;

-- route_from
SELECT DISTINCT route_from FROM safari_connect.bookings_raw;

-- route_to
SELECT DISTINCT route_to FROM safari_connect.bookings_raw;

-- vehicle_plate
SELECT DISTINCT vehicle_plate FROM safari_connect.bookings_raw;

-- vehicle_type
-- standardize to Title Case
SELECT DISTINCT
	vehicle_type AS raw_vehicle_type,
	INITCAP(vehicle_type) AS vehicle_type
FROM safari_connect.bookings_raw;

-- driver_name
-- standardize to Title Case
SELECT DISTINCT
	driver_name AS raw_driver_name,
	INITCAP(driver_name) AS driver_name 
FROM safari_connect.bookings_raw;

-- driver_rating
SELECT DISTINCT driver_rating FROM safari_connect.safari_connect_dirty;

-- departure_date
SELECT DISTINCT departure_date FROM safari_connect.safari_connect_dirty;

-- departure_time


-- seat_class
SELECT DISTINCT 
	seat_class AS raw_seat_class,
	CASE
    		WHEN UPPER(TRIM(seat_class)) IN ('ECONOMY','ECO','ECONOMY CLASS') THEN 'Economy'
    		WHEN UPPER(TRIM(seat_class)) IN ('BUSINESS','BUS','BUSINESS CLASS') THEN 'Business'
    ELSE seat_class
	END AS seat_class 
FROM safari_connect.safari_connect_dirty;

-- seats_booked
SELECT DISTINCT seats_booked FROM safari_connect.trips;

-- fare_per_seat
SELECT DISTINCT
	fare_per_seat AS raw_fare_per_sit,
	CASE 
		WHEN fare_per_seat ILIKE 'KES%' THEN SUBSTRING(REPLACE(fare_per_seat, ',', ''), '[-0-9]+')
		ELSE fare_per_seat 
	END::NUMERIC AS fare_per_seat
FROM safari_connect.bookings_raw;

-- total_fare
-- standardize - remove prefix 'KES'
SELECT DISTINCT
	total_fare AS raw_total_fare,
	CASE 
		WHEN total_fare ILIKE 'KES%' THEN SUBSTRING(REPLACE(total_fare, ',', ''), '[-0-9]+')
		ELSE total_fare 
	END::NUMERIC AS total_fare
FROM safari_connect.bookings_raw;

-- payment_method
-- standardize lower, upper case to title case
-- Mpesa to M-Pesa
SELECT DISTINCT
	CASE 
		WHEN INITCAP(payment_method) = 'Mpesa' THEN 'M-Pesa'
		ELSE INITCAP(payment_method)
	END AS payment_method 
FROM safari_connect.bookings_raw;

-- booking_status
-- standardize to Title Case
SELECT DISTINCT INITCAP(booking_status) AS booking_status FROM safari_connect.bookings_raw;

-- trip_rating
-- standardize invalid trip_rating to NULL (0 or > 5)
SELECT DISTINCT 
    trip_rating AS raw_trip_rating,
    CASE 
        -- Handle NULL, empty string, or whitespace
        WHEN trip_rating IS NULL OR TRIM(trip_rating) = '' THEN NULL
        -- Handle ratings outside the valid 1-5 range
        WHEN trip_rating::INT < 1 OR trip_rating::INT > 5 THEN NULL
        ELSE trip_rating
    END::INT AS trip_rating
FROM safari_connect.safari_connect_dirty;

-- Remove dashes and special characters
update safari_connect.bookings_staging 
set passenger_phone = regexp_replace(passenger_phone, '[^0-9+]','','g')
where passenger_phone is not null and passenger_phone !~ '^0[0-9]{9}$';

-- Remove +254 and swap with 0
update safari_connect.bookings_staging 
set passenger_phone = regexp_replace(passenger_phone, '^\+254','0')
where passenger_phone like '+254%';

-- Convert empty strings to null
update safari_connect.bookings_staging 
set passenger_phone = coalesce(nullif(passenger_phone,''),null)
where passenger_phone = '';

update bookings_staging bs
set departure_date = CASE
-- Already YYYY-MM-DD
WHEN departure_date ~ '^\d{4}-\d{2}-\d{2}$'
THEN departure_date::DATE
-- DD/MM/YYYY
WHEN departure_date ~ '^\d{2}/\d{2}/\d{4}$'
THEN TO_DATE(departure_date, 'DD/MM/YYYY')
-- DD-MM-YY
WHEN departure_date ~ '^\d{2}-\d{2}-\d{2}$'
THEN TO_DATE(departure_date, 'DD-MM-YY')
-- MM-DD-YYYY
WHEN departure_date ~ '^\d{2}-\d{2}-\d{4}$'
THEN TO_DATE(departure_date, 'MM-DD-YYYY')
ELSE NULL
end; 
