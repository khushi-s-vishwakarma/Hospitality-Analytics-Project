create database Hospitality_project;
use hospitality_project;

create table if not exists fact_bookings(
		booking_id varchar(50),
		property_id int,
		booking_date date,
		check_in_date date,
		checkout_date date,
		no_guests int,
		room_category varchar(3),
		booking_platform varchar(50),
		ratings_given varchar(10),
		booking_status varchar(50),
		revenue_generated decimal(15,2),
		revenue_realized decimal(15,2)
);

select * from fact_bookings;
drop table fact_bookings;

-- loading data into the table 

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Hospitality project\\fact_bookings.csv'
INTO TABLE fact_bookings
FIELDS TERMINATED BY ','  -- If your CSV is comma-separated
ENCLOSED BY '"'            -- If your values are enclosed in double quotes
LINES TERMINATED BY '\n'   -- For line breaks
IGNORE 1 LINES; 

create table if not exists fact_aggregated_bookings(
				property_id int,
				check_in_date date,
				room_category varchar(5),
				successful_bookings int,
				capacity int
);

select * from fact_aggregated_bookings;
drop table fact_aggregated_bookings;

-- loading data into the table 
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Hospitality project\\fact_aggregated_bookings.csv'
INTO TABLE fact_aggregated_bookings
FIELDS TERMINATED BY ','  -- If your CSV is comma-separated
ENCLOSED BY '"'            -- If your values are enclosed in double quotes
LINES TERMINATED BY '\n'   -- For line breaks
IGNORE 1 LINES; 

create table if not exists dim_rooms(
			room_id varchar(3),
			room_class varchar(50)
);

select * from dim_rooms;

-- loading data into the table 
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Hospitality project\\dim_rooms.csv'
INTO TABLE dim_rooms
FIELDS TERMINATED BY ','  -- If your CSV is comma-separated
ENCLOSED BY '"'            -- If your values are enclosed in double quotes
LINES TERMINATED BY '\n'   -- For line breaks
IGNORE 1 LINES; 



create table if not exists dim_hotels(
		property_id int,
		property_name varchar(50),
		category varchar(50),
		city varchar(50)
        );
        
select * from dim_hotels;

-- loading data into the table 
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Hospitality project\\dim_hotels.csv'
INTO TABLE dim_hotels
FIELDS TERMINATED BY ','  -- If your CSV is comma-separated
ENCLOSED BY '"'            -- If your values are enclosed in double quotes
LINES TERMINATED BY '\n'   -- For line breaks
IGNORE 1 LINES; 

create table if not exists dim_date(
		dim_dates date,
		dim_week_no varchar(20),
		day_type varchar(20)
        );
select * from dim_date;
drop table dim_date;

-- loading data into the table 
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Hospitality project\\dim_date.csv'
INTO TABLE dim_date
FIELDS TERMINATED BY ','  -- If your CSV is comma-separated
ENCLOSED BY '"'            -- If your values are enclosed in double quotes
LINES TERMINATED BY '\n'   -- For line breaks
IGNORE 1 LINES; 


-- Questions? & > Answers.alter

-- 1) total revenue?
select 
	sum(revenue_realized) 
from fact_bookings;

-- 2) occupancy ?
select 
	sum(successful_bookings)/sum(capacity)*100 as occupancy_rate 
from fact_aggregated_bookings;

-- 3)cancellation rate?
SELECT 
    COUNT(CASE WHEN booking_status = 'cancelled' THEN 1 END) AS cancellations,
    COUNT(booking_status) AS total_bookings,
    ROUND((COUNT(CASE WHEN booking_status = 'cancelled' THEN 1 END) / COUNT(booking_status)) * 100, 2) AS cancellation_rate
FROM 
    fact_bookings;

-- 4) total bookings?
select count(booking_id) from fact_bookings;
	
-- 5) utilized capacity?    
SELECT 
    COUNT(CASE WHEN booking_status = 'checked out' THEN 1 END) AS utilized_room,
    COUNT(booking_status) AS total_bookings,
    ROUND((COUNT(CASE WHEN booking_status = 'checked out' THEN 1 END) / COUNT(booking_status)) * 100, 2) AS utilized_capacity
FROM 
    fact_bookings;

-- 6)Trend analysis?
/*
CREATE INDEX idx_property_id_fb ON fact_bookings(property_id);
CREATE INDEX idx_property_id_fab ON fact_aggregated_bookings(property_id);

SET GLOBAL net_read_timeout=28800;
SET GLOBAL net_write_timeout=28800;

SET GLOBAL wait_timeout=28800;
SET GLOBAL interactive_timeout=28800;
*/
/*
SELECT 
	fb.check_in_date,
    sum(fab.successful_bookings) as booked_rooms,
    sum(fab.capacity) AS available_rooms,
	sum(fab.successful_bookings)/sum(fab.capacity)*100 as occupancy_rate ,
	ROUND(SUM(fb.revenue_realized) / sum(fab.successful_bookings), 2) AS ADR,
    ROUND(SUM(fb.revenue_realized) / sum(fab.capacity), 2) AS RevPar
FROM 
    fact_bookings fb
JOIN 
    fact_aggregated_bookings fab 
ON fb.property_id = fab.property_id
group by 	fb.check_in_date
;
*/

SELECT 
    check_in_date,
	count(booking_id),
	COUNT(CASE WHEN booking_status = 'checked out' THEN 1 END) AS occupied_rooms,
	COUNT(DISTINCT booking_id) AS available_rooms,
    ROUND((COUNT(CASE WHEN booking_status = 'checked out' THEN 1 END) / COUNT(DISTINCT booking_id)) * 100, 2) AS occupancy_rate,
    ROUND(SUM(revenue_realized) / NULLIF(COUNT(CASE WHEN booking_status = 'checked out' THEN 1 END), 0), 2) AS adr,
    ROUND(SUM(revenue_realized) / NULLIF(COUNT(DISTINCT booking_status), 0), 2) AS revpar
FROM 
    fact_bookings fb																								-- NULLIF(expression1, expression2)-->1)If expression1 is equal to expression2, the function returns NULL
WHERE 																																					-- 2)If they are not equal, the function returns expression1
    check_in_date BETWEEN '2022-05-01' AND '2022-07-31'																		
GROUP BY 
    check_in_date;

-- 7)weekend vs weekday by revenue and booking?
SELECT 
    CASE 
        WHEN DAYOFWEEK(check_in_date) IN (6, 7) THEN 'Weekend' -- Sunday (1) and Saturday (7) considered friday & saturday as weekend
        ELSE 'Weekday' -- sunday (1) to thursday (5)
    END AS day_type,
    COUNT(booking_id) AS total_bookings,
    SUM(revenue_realized) AS total_revenue,
    ROUND(AVG(revenue_realized), 2) AS avg_revenue_per_booking
FROM 
    fact_bookings
GROUP BY 
    day_type
ORDER BY 
	day_type;

-- 8) Revenue by State & hotel?
select 
	sum(fb.revenue_realized),
    dh.city,
    dh.property_name
from 
	fact_bookings fb 
join dim_hotels dh 
    on fb.property_id=dh.property_id
group by dh.city ,dh.property_name;
 

-- 9) Class Wise Revenue?
select
	dm.room_class,
    sum(fb.revenue_realized) as Total_Revenue
from 
	fact_bookings fb 
    join dim_rooms dm 
    on fb.room_category=dm.room_id
group by dm.room_class
order by total_revenue desc;

-- 10) Checked out cancel No show?
SELECT
    booking_status,
    count(booking_id),
    sum(revenue_realized) as total_revenue
   /* CASE
        WHEN booking_status = 'Checked Out' THEN 'Checked  Out'
        WHEN booking_status = 'Cancelled' THEN 'Cancelled'
        ELSE 'No-Show'
    END AS hotel_booking_status
    */
FROM
    fact_bookings
group by booking_status;

-- 11) Weekly trend Key trend (Revenue, Total booking, Occupancy) 
SELECT 
	sum(revenue_realized) as Revenue ,
    count(booking_id),
    WEEK(check_in_date, 7) AS booking_week,  -- Week number (7 = sunday start)
    COUNT(CASE WHEN booking_status = 'checked out' THEN 1 END) AS occupied_rooms,
     COUNT(DISTINCT booking_id) AS available_rooms,
    ROUND((COUNT(CASE WHEN booking_status = 'checked out' THEN 1 END) / COUNT(DISTINCT booking_id)) * 100, 2) AS occupancy_rate,
    ROUND(SUM(revenue_realized) / NULLIF(COUNT(CASE WHEN booking_status = 'checked out' THEN 1 END), 0), 2) AS adr,
    ROUND(SUM(revenue_realized) / NULLIF(COUNT(DISTINCT booking_status), 0), 2) AS revpar
FROM 
    fact_bookings 
WHERE 
    check_in_date BETWEEN '2022-05-01' AND '2022-07-31'
GROUP BY 
    WEEK(check_in_date, 7)
ORDER BY 
    booking_week;


/* SELECT 
	sum(fb.revenue_realized) as Revenue ,
    count(fb.booking_id),
    WEEK(fb.check_in_date, 7) AS booking_week,  -- Week number (7 = sunday start)
    COUNT(CASE WHEN fb.booking_status = 'checked out' THEN 1 END) AS occupied_rooms,
    COUNT(DISTINCT fb.booking_id) AS available_rooms,
    sum(fab.successful_bookings)/sum(fab.capacity)*100 as occupancy_rate ,
    ROUND(SUM(fb.revenue_realized) / sum(fab.successful_bookings), 2) AS ADR,
    ROUND(SUM(fb.revenue_realized) / sum(fab.capacity), 2) AS RevPar
FROM 
    fact_bookings fb
JOIN 
    fact_aggregated_bookings fab 
ON fb.property_id = fab.property_id
WHERE 
    fb.check_in_date BETWEEN '2022-05-01' AND '2022-07-31'
GROUP BY 
    WEEK(fb.check_in_date, 7)
ORDER BY 
    booking_week;
*/

