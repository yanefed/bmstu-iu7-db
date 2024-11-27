create extension if not exists plpython3u;

-- скалярная функция
create or replace function public.get_status(status int)
    returns varchar
    language plpython3u
as
$$
    if status == 0:
        return "Created"
    elif status == 1:
        return "Confirmed"
    elif status == 2:
        return "Finished"
    elif status == 3:
        return "Paid"
    if status == -1:
        return "Cancelled"
    else:
        raise Exception("Invalid status")
$$;

select public.get_status(1);

-- агрегатная функция
create or replace function public.get_rehearsal_cost(id int)
    returns int
    language plpython3u
as
$$
    query = plpy.prepare(
        "select h.hour, rm.price_per_hour from public.rehearsal as re " +
        "join public.rehearsals_in_room as rir on re.rehearsal_id = rir.rehearsal_id " +
        "join public.room as rm on rir.room_id = rm.room_id " +
        "join public.hour as h on re.rehearsal_id = h.rehearsal_id " +
        "where re.rehearsal_id = $1", ["int"]
    )
    res = plpy.execute(query, [id])
    cost = 0
    if res is not None:
        cost = len(res) * res[0]["price_per_hour"]

    return cost
$$;

select public.get_rehearsal_cost(1);

-- табличная функция

create or replace function public.py_get_rehearsals_in_room(room_id int)
    returns table
            (
                rehearsal_id    int,
                date            date,
                additional_info text,
                status          int
            )
    language plpython3u
as
$$
    query = plpy.prepare(
        "select re.rehearsal_id, re.date, re.additional_info, rir.status from public.rehearsal as re " +
        "join public.rehearsals_in_room as rir on re.rehearsal_id = rir.rehearsal_id " +
        "where rir.room_id = $1", ["int"]
    )
    res = plpy.execute(query, [room_id])
    res_table = list()
    if res is not None:
        for i in res:
            res_table.append(i)
    return res_table
$$;


select *
from public.py_get_rehearsals_in_room(1);

-- хранимая процедура

create or replace procedure add_hours_for_day(day date default current_date + interval '1 day')
    language plpython3u
as
$$
    query = plpy.prepare(
        "select room_id from public.room", []
    )
    rooms = plpy.execute(query)

    for room in rooms:
        for i in range(24):
            query = plpy.prepare(
                "insert into public.hour (room_id, date, hour) values ($1, $2, $3)", ["int", "date", "int"]
            )
            plpy.execute(query, [room["room_id"], day, i])
$$;

call add_hours_for_day('2025-01-01');

select *
from public.hour
where date = '2025-01-01';

-- триггер AFTER. Освобождение часов отмененной репетиции, если отмена за день до

create or replace function py_cancel_rehearsal_free_hour()
    returns trigger
    language plpython3u
as
$$
    query = plpy.prepare(
        "select rehearsal.date from public.rehearsal " +
        "join public.rehearsals_in_room rir on rir.rehearsal_id = rehearsal.rehearsal_id " +
        "where rehearsal.rehearsal_id = $1", ["int"]
    )
    res = plpy.execute(query, [TD["new"]["rehearsal_id"]])
    rehearsal_date = res[0]["date"] if res else None

    if TD["new"]["status"] == -1 and rehearsal_date > plpy.execute("select current_date")[0]["current_date"]:
        plpy.notice("Отмена репетиции %s" % TD["new"]["rehearsal_id"])
        query = plpy.prepare(
            "update public.hour set rehearsal_id = NULL " +
            "where room_id = $1 and rehearsal_id = $2 and date > current_date", ["int", "int"]
        )
        plpy.execute(query, [TD["new"]["room_id"], TD["new"]["rehearsal_id"]])


$$;;

create or replace trigger py_cancel_rehearsal_free_hour
    after update of status
    ON public.rehearsals_in_room
    for each row
execute procedure py_cancel_rehearsal_free_hour();

insert into public.rehearsal (date, customer_id, additional_info)
values ('2024-10-16', 1, 'test_after_trigger');

select max(rehearsal_id)
from public.rehearsal;

insert into public.hour (date, hour, room_id, rehearsal_id)
values ('2024-10-16', 12, 1, 25252),
       ('2024-10-16', 13, 1, 25252),
       ('2024-10-16', 14, 1, 25252);
insert into public.rehearsals_in_room (rehearsal_id, room_id, status)
values (25252, 1, 1);

update public.rehearsals_in_room as rir
set status = -1
where rir.rehearsal_id = 25252;

select *
from public.hour
where hour.date = '2024-10-16'
  and hour.room_id = 1
  and hour.hour in (12, 13, 14);

delete
from public.hour
where hour.date = '2024-10-16'
  and hour.room_id = 1
  and hour.hour in (12, 13, 14);

-- пользовательский тип данных

create type public.rehearsal_info as
(
    rehearsal_id    int,
    date            date,
    room_name       text,
    customer_name   text,
    additional_info text,
    status          int
);

create or replace function public.get_rehearsal_info(rehearsal_id int)
    returns setof public.rehearsal_info
    language plpython3u
as
$$
    query = plpy.prepare(
        "select re.rehearsal_id, re.date, rm.name as room_name, cu.name as customer_name, re.additional_info, rir.status from public.rehearsal as status " +
        "join public.rehearsals_in_room as rir on re.rehearsal_id = rir.rehearsal_id " +
        "join public.room as rm on rir.room_id = rm.room_id " +
        "join public.customer as cu on re.customer_id = cu.customer_id " +
        "where re.rehearsal_id = $1", ["int"]
    )
    res = plpy.execute(query, [rehearsal_id])
    res_table = list()
    if res is not None:
        for i in res:
            res_table.append(i)
    return res_table
$$;

select *
from public.get_rehearsal_info(1);

