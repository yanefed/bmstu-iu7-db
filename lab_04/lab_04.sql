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


select * from public.py_get_rehearsals_in_room(1);