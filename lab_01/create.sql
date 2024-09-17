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
    hour_id      serial,
    room_id      int,
    rehearsal_id int,
    date         date,
    hour         int
);

CREATE TABLE IF NOT EXISTS rehearsal
(
    rehearsal_id    serial,
    date            date,
    customer_id     int,
    customer_rate   int,
    room_rate       int,
    additional_info text
);

CREATE TABLE IF NOT EXISTS rehearsals_in_room
(
    id           serial,
    rehearsal_id int,
    room_id      int,
    status       int
)


