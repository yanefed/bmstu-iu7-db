COPY customer (customer_id, name, phone_number, email, ban)
    FROM '/tmp/customers.csv'
    DELIMITER ','
    CSV HEADER;


COPY room (room_id, name, address, price_per_hour, min_hours)
    FROM '/tmp/rooms.csv'
    DELIMITER ','
    CSV HEADER;

COPY hour (hour_id, room_id, date, hour, available)
    FROM '/tmp/hours.csv'
    DELIMITER ','
    CSV HEADER;


COPY rehearsal (rehearsal_id, customer_id, date, customer_rate, room_rate, status)
    FROM '/tmp/rehearsals.csv'
    DELIMITER ','
    CSV HEADER;


COPY rehearsals_in_room (id, rehearsal_id, room_id, paid)
    FROM '/tmp/rehearsal_rooms.csv'
    DELIMITER ','
    CSV HEADER;


COPY hours_in_rehearsal (id, rehearsal_id, hour_id)
    FROM '/tmp/rehearsal_hours.csv'
    DELIMITER ','
    CSV HEADER;


