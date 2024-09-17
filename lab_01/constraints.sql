alter table postgres.public.room
    add constraint pk_room_id primary key (room_id),

    add constraint valid_name check ( name != '' ),
    add constraint unique_name unique (name),
    add constraint valid_address check ( address != '' ),
    add constraint valid_pph check ( price_per_hour >= 0 ),
    add constraint valid_hours check ( min_hours >= 0 ),

    alter column name set not null,
    alter column address set not null,
    alter column price_per_hour set default 0,
    alter column price_per_hour set not null,
    alter column min_hours set default 1,
    alter column min_hours set not null;


alter table postgres.public.customer
    add constraint pk_customer_id primary key (customer_id),

    add constraint valid_name check ( name != '' ),
    add constraint valid_phone_number check ( phone_number != '' ),
    add constraint unique_phone_number unique (phone_number),
    add constraint valid_email check ( email != '' ),
    add constraint unique_email unique (email),

    alter column name set not null,
    alter column phone_number set not null,
    alter column email set not null,
    alter column ban set not null;

alter table postgres.public.rehearsal
    add constraint pk_rehearsal_id primary key (rehearsal_id),
    add constraint fk_customer_id foreign key (customer_id) references postgres.public.customer,

    add constraint valid_customer_rate check ( 0 < customer_rate and customer_rate <= 5 ),
    add constraint valid_room_rate check ( 0 < room_rate and room_rate <= 5 ),
    add constraint valid_info check ( additional_info != '' ),

    alter column date set not null,
    alter column additional_info set not null;

alter table postgres.public.hour
    add constraint pk_hour_id primary key (hour_id),
    add constraint fk_room_id foreign key (room_id) references postgres.public.room,
    add constraint fk_rehearsal_id foreign key (rehearsal_id) references postgres.public.rehearsal,

    add constraint valid_hour check ( 0 <= hour and hour < 24),

    alter column date set not null,
    alter column hour set not null;

alter table postgres.public.rehearsals_in_room
    add constraint pk_rir primary key (id),
    add constraint fk_rehearsal_id foreign key (rehearsal_id) references postgres.public.rehearsal,
    add constraint fk_room_id foreign key (room_id) references postgres.public.room,
    add constraint valid_status check ( 0 < status and status <= 3 ),

    alter column status set not null;
