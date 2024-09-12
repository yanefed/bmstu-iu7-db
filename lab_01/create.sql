CREATE TABLE IF NOT EXISTS room
(
    room_id        serial,
    name           text,
    address        text,
    price_per_hour int,
    min_hours      int
);

CREATE TABLE IF NOT EXISTS customer
(
    customer_id  serial,
    name         text,
    phone_number text,
    email        text,
    ban          boolean
);

CREATE TABLE IF NOT EXISTS hour
(
    hour_id   serial,
    room_id   int,
    date      date,
    hour      int,
    available boolean
);

CREATE TABLE IF NOT EXISTS rehearsal
(
    rehearsal_id  serial,
    date          date,
    customer_id   int,
    customer_rate int,
    room_rate     int,
    status        int
);

CREATE TABLE IF NOT EXISTS hours_in_rehearsal
(
    id           serial,
    hour_id      int,
    rehearsal_id int
);

CREATE TABLE IF NOT EXISTS rehearsals_in_room
(
    id           serial,
    rehearsal_id int,
    room_id      int,
    paid         boolean
)


