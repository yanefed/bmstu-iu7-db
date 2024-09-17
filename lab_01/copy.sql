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
