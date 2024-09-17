COPY customer (customer_id, name, phone_number, email, ban)
    FROM '/tmp/customers.csv'
    DELIMITER ','
    CSV HEADER;

COPY room (room_id, name, address, price_per_hour, min_hours)
    FROM '/tmp/rooms.csv'
    DELIMITER ','
    CSV HEADER;

COPY rehearsal (rehearsal_id, customer_id, date, customer_rate, room_rate, additional_info)
    FROM '/tmp/rehearsals.csv'
    DELIMITER ','
    CSV HEADER;

COPY hour (hour_id, room_id, date, hour, rehearsal_id)
    FROM '/tmp/hours.csv'
    DELIMITER ','
    CSV HEADER;

COPY rehearsals_in_room (id, rehearsal_id, room_id, status)
    FROM '/tmp/rehearsal_rooms.csv'
    DELIMITER ','
    CSV HEADER;


SELECT setval(pg_get_serial_sequence('postgres.public.rehearsal', 'rehearsal_id'), COALESCE(MAX(rehearsal_id), 1) + 1,
              false)
FROM postgres.public.rehearsal;

SELECT setval(pg_get_serial_sequence('postgres.public.customer', 'customer_id'), COALESCE(MAX(customer_id), 1) + 1,
              false)
FROM postgres.public.customer;

SELECT setval(pg_get_serial_sequence('postgres.public.room', 'room_id'), COALESCE(MAX(room_id), 1) + 1,
              false)
FROM postgres.public.room;

SELECT setval(pg_get_serial_sequence('postgres.public.hour', 'hour_id'), COALESCE(MAX(hour_id), 1) + 1,
              false)
FROM postgres.public.hour;

SELECT setval(pg_get_serial_sequence('postgres.public.rehearsals_in_room', 'id'), COALESCE(MAX(id), 1) + 1,
              false)
FROM postgres.public.rehearsals_in_room;

