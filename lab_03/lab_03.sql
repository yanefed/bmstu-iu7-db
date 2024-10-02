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
end;
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
select hour.rehearsal_id, hour.hour
from hour
where hour.rehearsal_id = 1
group by hour.rehearsal_id, hour.hour;


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
                 join public.room rm on rm.room_id = rir.room_id
        where r.customer_id = find_user_id
        loop
            return query
                select rehearsal.rehearsal_id,
                       rehearsal.rehearsal_date,
                       rehearsal.room_name,
                       public.get_first_hour_of_rehearsal(rehearsal.rehearsal_id),
                       public.get_last_hour_of_rehearsal(rehearsal.rehearsal_id);
        end loop;
end;
$$ language plpgsql;

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

select *
from fib(1, 1, 14);

-- 5. Удалить неиспользованные часы

create or replace procedure clear_unused_hours(day date default current_date)
as
$$
begin
    delete
    from public.hour
    where public.hour.date < day
      and public.hour.rehearsal_id is null;
end;
$$
    language plpgsql;

-- 6. Получить число Фибоначчи с заданным индексом
create or replace procedure fib_index(res inout int, index int, start int default 0, end_ int default 1)
as
$$
begin
    if index > 0 then
        res = start + end_;
        call fib_index(res, index - 1, end_, start + end_);
    end if;
end;
$$
    language plpgsql;

call fib_index(1, 6);

-- 7. Удалить неиспользуемые часы (с использованием курсора)
create or replace procedure clear_unused_hours_cur(day date default current_date)
as
$$
declare
    hour_date    date;
    hour_hour    int;
    room_name    text;
    hour_room_id int;
    counter      int := 0;
    cur cursor for
        select hour.date, hour.hour, r.name, hour.room_id
        from public.hour
                 join public.room r on r.room_id = hour.room_id
        where public.hour.date < day
          and public.hour.rehearsal_id is null;
begin
    open cur;
    loop
        fetch cur into hour_date, hour_hour, room_name, hour_room_id;
        exit when not found;
        delete
        from public.hour
        where public.hour.date = hour_date
          and public.hour.hour = hour_hour
          and public.hour.room_id = hour_room_id;
        counter := counter + 1;
        raise notice 'В комнате "%" % числа удален временной слот в %', room_name, hour_date, hour_hour;
    end loop;
    raise notice 'Удалено % временных слотов', counter;
    close cur;
end;
$$
    language plpgsql;

call clear_unused_hours_cur('2024-09-03');

-- 8. Информация о типах данных аттрибутов таблицы
create or replace procedure get_meta(name text) as
$$
declare
    buf record;
    myCursor cursor
        for
        select column_name, data_type
        from information_schema.columns
        where table_name = name;
begin
    raise notice 'Table %:', name;
    open myCursor;
    loop
        fetch myCursor
            into buf;
        exit WHEN NOT FOUND;
        raise notice '% [%]', buf.column_name, buf.data_type;
    end loop;
    close myCursor;
end
$$
    language plpgsql;


call get_meta('hour');

-- 9. Триггер AFTER. Освобождение часов отмененной репетиции, если отмена за
create or replace function cancel_rehearsal_free_hour()
    returns trigger as
$$
declare
    rehearsal_date date;
begin
    select rehearsal.date
    from rehearsal
             join rehearsals_in_room rir on rir.rehearsal_id = rehearsal.rehearsal_id
    where rehearsal.rehearsal_id = NEW.rehearsal_id
    into rehearsal_date;

    if NEW.status = -1 and rehearsal_date > current_date then
        raise notice 'Отмена репетиции %', NEW.rehearsal_id;
        update hour
        set rehearsal_id = NULL
        where room_id = NEW.room_id
          and hour.rehearsal_id = NEW.rehearsal_id
          and rehearsal_date > current_date;
    end if;

    return NEW;
end;
$$ language plpgsql;

create or replace trigger cancel_rehearsal_free_hour
    after update of status
    ON public.rehearsals_in_room
    for each row
execute procedure cancel_rehearsal_free_hour();

insert into public.rehearsal (date, customer_id, additional_info)
values ('2024-10-03', 1, 'test_after_trigger');

select max(rehearsal_id)
from public.rehearsal;

insert into public.hour (date, hour, room_id, rehearsal_id)
values ('2024-10-03', 12, 1, 25246),
       ('2024-10-03', 13, 1, 25246),
       ('2024-10-03', 14, 1, 25246);
insert into public.rehearsals_in_room (rehearsal_id, room_id, status)
values (25246, 1, 1);

update public.rehearsals_in_room as rir
set status = -1
where rir.rehearsal_id = 25246;

select *
from public.hour
where hour.date = '2024-10-03'
  and hour.room_id = 1
  and hour.hour in (12, 13, 14);

delete
from public.hour
where hour.date = '2024-10-03'
  and hour.room_id = 1
  and hour.hour in (12, 13, 14);

-- 10. Триггер INSTEAD OF

create or replace view full_rehearsals as
select r.rehearsal_id                                     as id,
       rm.name                                            as room,
       r.date                                             as date,
       public.get_first_hour_of_rehearsal(r.rehearsal_id) as beginning,
       public.get_last_hour_of_rehearsal(r.rehearsal_id)  as ending,
       rir.status                                         as status,
       r.additional_info                                  as additional_info,
       c.name                                             as customer_name,
       c.email                                            as email,
       c.phone_number                                     as phone_number

from public.rehearsal r
         join public.rehearsals_in_room rir on r.rehearsal_id = rir.rehearsal_id
         join public.room rm on rir.room_id = rm.room_id
         join public.customer c on r.customer_id = c.customer_id;

select *
from full_rehearsals
where date = '2024-10-03';

create or replace function add_full_rehearsal()
    returns trigger as
$$
declare
    var_room_id      int;
    var_customer_id  int;
    var_rehearsal_id int;
begin
    var_room_id := (select room_id from public.room where name = NEW.room);

    insert into public.customer (name, phone_number, email, ban)
    values (NEW.customer_name, NEW.phone_number, NEW.email, false)
    on conflict do nothing;

    var_customer_id := (select customer_id
                        from public.customer
                        where name = NEW.customer_name
                          and phone_number = NEW.phone_number
                          and email = NEW.email);

    insert into public.rehearsal (date, customer_id, additional_info)
    values (NEW.date, var_customer_id, NEW.additional_info)
    returning rehearsal_id into var_rehearsal_id;

    insert into public.rehearsals_in_room (rehearsal_id, room_id, status)
    values (var_rehearsal_id, var_room_id, NEW.status);

    if (select count(hour.hour_id)
        from public.hour
        where room_id = var_room_id
          and date = NEW.date
          and hour.hour between NEW.beginning and NEW.ending
          and hour.rehearsal_id is not null) > 0
    then
        raise exception 'Временной слот уже занят';
    end if;

    update public.hour
    set rehearsal_id = var_rehearsal_id
    where date = NEW.date
      and room_id = (select room_id from public.room where name = NEW.room)
      and hour between NEW.beginning and NEW.ending;

    return NEW;
end;
$$ language plpgsql;

create trigger add_full_rehearsal
    instead of insert
    on full_rehearsals
    for each row
execute function add_full_rehearsal();

insert into full_rehearsals (room, date, beginning, ending, status, additional_info, customer_name, email, phone_number)
values ('DarkViolet', '2024-10-04', 12, 15, 1, 'test', 'test', 'test@email.com', '+79999999999');

select *
from full_rehearsals
where date = '2024-10-04'
  and room = 'DarkViolet'
  and beginning = 12
  and ending = 15;


-- Защита
-- функция получает название группы и возвращает комнату, в которой она чаще всего бывает

create or replace function get_room_of_group(group_name text)
    returns text as
$$
declare
    room_name text;
begin
    select rm.name
    into room_name
    from public.rehearsal as re
             join public.rehearsals_in_room as rir on rir.rehearsal_id = re.rehearsal_id
             join public.room as rm on rir.room_id = rm.room_id
             join public.customer as cu on cu.customer_id = re.customer_id
    where cu.name = group_name
    group by rm.name
    order by count(rm.name) desc
    limit 1;
    return room_name;
end;
$$
    language plpgsql;

select public.get_room_of_group('test');