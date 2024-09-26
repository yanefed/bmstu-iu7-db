-- Скалярные функции
-- 1. Вернуть последний час данной репетиции
create or replace function public.get_last_hour_of_rehearsal(id int)
    returns int as
$$
declare
    last_hour int;
begin
    select max(hour)
    into last_hour
    from public.hour
             join public.rehearsal r on r.rehearsal_id = hour.rehearsal_id
    where r.rehearsal_id = id;
    return last_hour;
end
$$
    language plpgsql;

create or replace function public.get_first_hour_of_rehearsal(id int)
    returns int as
$$
declare
    first_hour int;
begin
    select min(hour)
    into first_hour
    from public.hour
             join public.rehearsal r on r.rehearsal_id = hour.rehearsal_id
    where r.rehearsal_id = id;
    return first_hour;
end;
$$
    language plpgsql;

select public.get_first_hour_of_rehearsal(1);
select public.get_last_hour_of_rehearsal(1);


-- 2. Получить данные о репетициях, проходящих сегодня в данной комнате
create or replace function public.get_rehearsals_today_in_room(room_name varchar(64))
    returns table
            (
                room            text,
                customer_name   text,
                date            date,
                start_hour      int,
                end_hour        int,
                additional_info text
            )
as
$$
select public.room.name,
       public.customer.name,
       public.rehearsal.date,
       public.get_first_hour_of_rehearsal(public.rehearsal.rehearsal_id) as start,
       public.get_last_hour_of_rehearsal(public.rehearsal.rehearsal_id),
       public.rehearsal.additional_info
from public.rehearsal
         join public.hour on public.rehearsal.rehearsal_id = public.hour.rehearsal_id
         join public.room on public.hour.room_id = public.room.room_id
         join public.customer on public.rehearsal.customer_id = public.customer.customer_id
where public.room.name = room_name
  and public.rehearsal.date = current_date
group by public.rehearsal.rehearsal_id, public.room.name, public.customer.name, public.rehearsal.date,
         public.rehearsal.additional_info
order by start;
$$ language sql;

select *
from public.get_rehearsals_today_in_room('DarkViolet');

-- 3. Получить данные о репетициях пользователя
create or replace function get_rehearsals_of_customer(find_user_id int)
    returns table
            (
                rehearsal_id   int,
                rehearsal_date date,
                room_name      text,
                start_hour     int,
                end_hour       int
            )
as
$$
declare
    rehearsal record;
BEGIN
    for rehearsal in
        select r.rehearsal_id, r.date as rehearsal_date, rm.name as room_name
        from public.rehearsal r
                 join public.rehearsals_in_room rir on rir.rehearsal_id = r.rehearsal_id
                 join public.room rm ON rm.room_id = rir.room_id
        where r.customer_id = find_user_id
        loop
            return query
                select rehearsal.rehearsal_id,
                       rehearsal.rehearsal_date,
                       rehearsal.room_name,
                       public.get_first_hour_of_rehearsal(rehearsal.rehearsal_id),
                       public.get_last_hour_of_rehearsal(rehearsal.rehearsal_id);
        END loop;
END;
$$ LANGUAGE plpgsql;

select *
from public.get_rehearsals_of_customer(3);

-- 4. Числа Фибоначчи
create or replace function fib(first INT, second INT, max INT)
    returns table
            (
                fibonacci INT
            )
as
$$
begin
    return query
        select first;
    if second <= max then
        return query
            select *
            from fib(second, first + second, max);
    end if;
end
$$
    language plpgsql;

select * from fib(1, 1, 100);

