create schema if not exists safaari_connect;
set search_path to safaari_connect;
select * from safari_connect_dirty;

--Standardizing case in passenger_name column.
update safari_connect_dirty
set passenger_name = trim(initcap(lower(passenger_name)));

--Replace characters that are not integers with blank in the passenger_phone column.
update safari_connect_dirty
set passenger_phone = regexp_replace(passenger_phone, '[^0-9]', '', 'g')
where passenger_phone is not null;
--Replacing '254' with '0' to have a uniform phone number format.
update safari_connect_dirty
set passenger_phone = '0' || substring(passenger_phone from 4)
where passenger_phone like '254%';

select * from safari_connect_dirty
order by booking_id;

--Checking distinct values in passenger_gender column
select passenger_gender,count(*) as total
from safari_connect_dirty
group by passenger_gender;

--Standardizing case in passenger_gender
update safari_connect_dirty
set passenger_gender = case 
	when lower(passenger_gender) in ('m','male') then 'Male'
	when lower(passenger_gender) in ('f','female') then 'Female'
	else 'unknown'
end;

--Remove extra spaces in texts.
update safari_connect_dirty
set passenger_gender = trim(passenger_gender);

--Find missing phone numbers and replacing them with null.
update safari_connect_dirty
set passenger_phone = null
where passenger_phone = '';

select * from safari_connect_dirty
where passenger_phone is null;

select * from safari_connect_dirty
order by booking_id;

--Checking distinct city values.
select passenger_city,count(*) as total
from safari_connect_dirty
group by passenger_city;

--Standardizing city values.
update safari_connect_dirty
set passenger_city = case
	when trim(lower(passenger_city)) = 'mombasa' then 'Mombasa'
	when trim(lower(passenger_city)) = 'nairobi' then 'Nairobi'
	when trim(lower(passenger_city)) = 'nakuru' then 'Nakuru'
	when trim(lower(passenger_city)) = 'meru' then 'Meru'
	when trim(lower(passenger_city)) = 'nyeri' then 'Nyeri'
	when trim(lower(passenger_city)) = 'thika' then 'Thika'
	when trim(lower(passenger_city)) = 'eldoret' then 'Eldoret'
	when trim(lower(passenger_city)) = 'kisumu' then 'Kisumu'
	when trim(lower(passenger_city)) = 'machakos' then 'Machakos'
	else trim(initcap(lower(passenger_city)))
end;

--Replace missing city values with null
update safari_connect_dirty
set passenger_city = null
where passenger_city = '';

select * from safari_connect_dirty
order by booking_id;

--Change date formats from varchar to date type
alter table safari_connect_dirty
alter column departure_date type date
using
case
	when departure_date ~ '^\d{4}-\d{2}-\d{2}$' then to_date(departure_date, 'yyyy-mm-dd')
	when departure_date ~ '^\d{2}/\d{2}/\d{4}&' then to_date(departure_date, 'dd/mm/yyyy')
	when departure_date ~ '^\d{2}-\d{2}-\d{4}&' then to_date(departure_date, 'mm-dd-yyyy')
	when departure_date ~ '^\d{2}-\d{2}-\d{2}&' then to_date(departure_date, 'dd-mm-yy')
	else null
end;

--Changing time format from string to time
update safari_connect_dirty
SET departure_time = CAST(departure_time AS TIME);

--Standardizing case in seat_class column.
update safari_connect_dirty
set seat_class = case
	when trim(lower(seat_class)) in ('eco', 'economy') then 'Economy'
	when trim(lower(seat_class)) in ('bus', 'business', 'business class') then 'Business'
	else null
end;
--Standardizingh payment method values.
update safari_connect_dirty 
set payment_method = case 
	when trim(lower(payment_method)) = 'card' then 'Card'
	when trim(lower(payment_method)) = 'cash' then 'Cash'
	when trim(lower(payment_method)) in ('mpesa','m-pesa') then 'M-pesa'
	else null
end;

set search_path to safaari_connect;

--Checking distinct booking status values.
select booking_status,count(*) as total
from safari_connect_dirty
group by booking_status; 

--Standardizing booking status values.
update safari_connect_dirty
set booking_status = case 
	when trim(lower(booking_status)) = 'completed' then 'Completed'
	when trim(lower(booking_status)) = 'cancelled' then 'Cancelled'
	when trim(lower(booking_status)) = 'no show' then 'No show'
end;

--strip off 'KES' by removing non digit values.
update safari_connect_dirty
set fare_per_seat = regexp_replace(fare_per_seat, '[^0-9]','','g');

--strip off 'KES' by removing non digit values.
update safari_connect_dirty 
set total_fare = regexp_replace(total_fare, '[^0-9]','','g');


select * from safari_connect_dirty
order by booking_id;

--Standardizing driver's name
update safari_connect_dirty
set driver_name = trim(initcap(lower(driver_name)));

--Standardizing vehicle type values.
update safari_connect_dirty
set vehicle_type = case
	when trim(lower(vehicle_type)) = 'bus' then 'Bus'
	when trim(lower(vehicle_type)) = 'minibus' then 'Minibus'
	when trim(lower(vehicle_type)) = 'matatu' then 'Matatu'
	else null
end;

--Remove invalid trip ratings.
update safari_connect_dirty
set trip_rating = null 
where trip_rating < 1 or 
trip_rating > 5;

--Identifying duplicates
select booking_id,count(*) as total
from safari_connect_dirty
group by booking_id
having count(*) > 1;

set search_path to safaari_connect;

--Remove negative values.
update safari_connect_dirty
set seats_booked = abs(seats_booked);


select ctid, * from safari_connect_dirty;

--Deleting using ctid
delete from safari_connect_dirty 
where ctid = '(13,42)';

--Creating production table
create table booking_staging as
select * from safari_connect_dirty;

set search_path to safaari_connect;
select * from booking_staging;

create view v_clean_trips as
select * from booking_staging
where booking_status = 'Completed'
order by booking_staging.booking_id;

select * from v_clean_trips;



