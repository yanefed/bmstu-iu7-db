--1. Из таблиц базы данных, созданной в первой лабораторной работе, извлечь данные JSON
select row_to_json(cu)
from customer cu;

select row_to_json(ho)
from hour ho;

select row_to_json(re)
from rehearsal re;

select row_to_json(rir)
from rehearsals_in_room rir;

select row_to_json(ro)
from room ro;

--2. Выполнить загрузку и сохранение JSON файла в таблицу.
--Созданная таблица после всех манипуляций должна соответствовать таблице
--базы данных, созданной в первой лабораторной работе.

create table if not exists room_copy
(
    room_id        serial primary key,
    name           text,
    address        text,
    price_per_hour int,
    min_hours      int
);


copy
    (
    select row_to_json(ro)
    from room ro
    )
    to '/tmp/room.json';


create table if not exists import_table
(
    doc json
);

drop table room_copy;
drop table import_table;

copy import_table from '/tmp/room.json';

insert into room_copy(name, address, price_per_hour, min_hours)
select (doc ->> 'name')::text,
       (doc ->> 'address')::text,
       (doc ->> 'price_per_hour')::int,
       (doc ->> 'min_hours')::int
from import_table;

select *
from room_copy;


--3. Создать таблицу, в которой будет атрибут(-ы) с типом JSON, или добавить атрибут с JSON к уже существующей таблице.
--Заполнить атрибут правдоподобными данными с помощью команд INSERT или UPDATE.
drop table if exists lab5_task3_table;

create table if not exists lab5_task3_table
(
    id   serial primary key,
    info json
);

insert into lab5_task3_table(id, info)
values (1, '{
  "name": "Name1",
  "address": "Address1",
  "employees": [
    {
      "name": "Employee1",
      "position": "Position1"
    },
    {
      "name": "Employee2",
      "position": "Position2"
    }
  ]
}');

insert into lab5_task3_table(id, info)
values (2, '{
  "name": "Name2",
  "address": "Address2",
  "employees": [
    {
      "name": "Employee3",
      "position": "Position1"
    },
    {
      "name": "Employee4",
      "position": "Position2"
    }
  ]
}');

insert into lab5_task3_table(id, info)
values (3, '{
  "name": "Name3",
  "address": "Address3",
  "employees": [
    {
      "name": "Employee5",
      "position": "Position1"
    },
    {
      "name": "Employee6",
      "position": "Position2"
    }
  ]
}');

insert into lab5_task3_table(id, info)
values (4, '{
  "name": "Name4",
  "address": "Address4",
  "employees": [
    {
      "name": "Employee7",
      "position": "Position1"
    },
    {
      "name": "Employee8",
      "position": "Position2"
    }
  ]
}');


select *
from lab5_task3_table;

--4.1 Извлечь JSON фрагмент
select info
from lab5_task3_table
where id = 1;

--4.2. Извлечь значения конкретных узлов или атрибутов JSON документа
select info -> 'name' as name
from lab5_task3_table
where id = 1;

--4.3. Выполнить проверку существования узла или атрибута jsonb
select info -> 'employees' -> 0 as employee
from lab5_task3_table
where id = 1
  and info -> 'employees' -> 0 is not null;

--4.4. Изменить JSON документ
UPDATE lab5_task3_table
SET info = json_build_object(
        'name', 'New Name',
        'address', info ->> 'address',
        'employees', info ->> 'employees'
           )
WHERE info ->> 'name' = 'Name1';

select *
from lab5_task3_table;

--4.5. Разделить XML/JSON документ на несколько строк по узлам
select id,
       json_extract_path(info, 'name')    as name,
       json_extract_path(info, 'address') as address
from lab5_task3_table;