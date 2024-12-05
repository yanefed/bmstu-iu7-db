-- task 1

create table if not exists rk2_teacher
(
    id      serial primary key,
    fio     text not null,
    grade   text not null,
    kafedra text not null
);

create table if not exists rk2_theme
(
    id      serial primary key,
    teacher int  not null references rk2_teacher (id),
    theme   text not null
);

create table if not exists rk2_student
(
    id          int primary key references rk2_teacher (id),
    number      text not null unique,
    fio         text not null,
    faculty     text not null,
    study_group int  not null
);

create table if not exists rk2_mark
(
    id          serial primary key,
    number      text not null references rk2_student (number),
    gos_mark    int  not null,
    diplom_mark int  not null
);

alter table rk2_mark
    add constraint student_mark_unique unique (number, gos_mark, diplom_mark);

insert into rk2_teacher (fio, grade, kafedra)
values ('Иванов Иван Иванович', 'профессор', 'ИУ7'),
       ('Петров Петр Петрович', 'доцент', 'ИУ7'),
       ('Сидоров Сидор Сидорович', 'старший преподаватель', 'ИУ7'),
       ('Александров Александр Александрович', 'профессор', 'ИУ7'),
       ('Андреев Андрей Андреевич', 'доцент', 'ИУ7'),
       ('Владимиров Владимир Владимирович', 'старший преподаватель', 'ИУ7'),
       ('Алексеев Алексей Алексеевич', 'профессор', 'ИУ7'),
       ('Борисов Борис Борисович', 'доцент', 'ИУ7'),
       ('Васильев Василий Васильевич', 'старший преподаватель', 'ИУ7'),
       ('Григорьев Григорий Григорьевич', 'профессор', 'ИУ7'),
       ('Дмитриев Дмитрий Дмитриевич', 'доцент', 'ИУ7'),
       ('Евгеньев Евгений Евгеньевич', 'старший преподаватель', 'ИУ7'),
       ('Иванов Иван Иванович', 'профессор', 'ИУ7'),
       ('Петров Петр Петрович', 'доцент', 'ИУ7'),
       ('Сидоров Сидор Сидорович', 'старший преподаватель', 'ИУ7'),
       ('Александров Александр Александрович', 'профессор', 'ИУ7'),
       ('Андреев Андрей Андреевич', 'доцент', 'ИУ7'),
       ('Владимиров Владимир Владимирович', 'старший преподаватель', 'ИУ7'),
       ('Алексеев Алексей Алексеевич', 'профессор', 'ИУ7'),
       ('Борисов Борис Борисович', 'доцент', 'ИУ7'),
       ('Васильев Василий Васильевич', 'старший преподаватель', 'ИУ7'),
       ('Григорьев Григорий Григорьевич', 'профессор', 'ИУ7'),
       ('Дмитриев Дмитрий Дмитриевич', 'доцент', 'ИУ7'),
       ('Евгеньев Евгений Евгеньевич', 'старший преподаватель', 'ИУ7')
;

insert into rk2_theme (teacher, theme)
values (1, 'Тема 1'),
       (2, 'Тема 2'),
       (3, 'Тема 3'),
       (4, 'Тема 4'),
       (5, 'Тема 5'),
       (6, 'Тема 6'),
       (7, 'Тема 7'),
       (8, 'Тема 8'),
       (9, 'Тема 9'),
       (10, 'Тема 1'),
       (11, 'Тема 2'),
       (12, 'Тема 3'),
       (13, 'Тема 4'),
       (14, 'Тема 5'),
       (15, 'Тема 6'),
       (16, 'Тема 7'),
       (17, 'Тема 8'),
       (18, 'Тема 9'),
       (19, 'Тема 1'),
       (20, 'Тема 2'),
       (21, 'Тема 3'),
       (22, 'Тема 4'),
       (23, 'Тема 5'),
       (24, 'Тема 6')
;

insert into rk2_student (number, fio, faculty, study_group, id)
values ('1', 'Студент1', 'ИУ', 1, 1),
       ('2', 'Студент2', 'ИУ', 1, 2),
       ('3', 'Студент3', 'ИУ', 1, 3),
       ('4', 'Студент4', 'ИУ', 1, 4),
       ('5', 'Студент5', 'ИУ', 1, 5),
       ('6', 'Студент6', 'ИУ', 1, 6),
       ('7', 'Студент7', 'ИУ', 1, 7),
       ('8', 'Студент8', 'ИУ', 1, 8),
       ('9', 'Студент9', 'ИУ', 1, 9),
       ('10', 'Студент10', 'ИУ', 1, 10),
       ('11', 'Студент11', 'ИУ', 1, 11),
       ('12', 'Студент12', 'ИУ', 1, 12),
       ('13', 'Студент13', 'ИУ', 1, 13),
       ('14', 'Студент14', 'ИУ', 1, 14),
       ('15', 'Студент15', 'ИУ', 1, 15),
       ('16', 'Студент16', 'ИУ', 1, 16),
       ('17', 'Студент17', 'ИУ', 1, 17),
       ('18', 'Студент18', 'ИУ', 1, 18),
       ('19', 'Студент19', 'ИУ', 1, 19),
       ('20', 'Студент20', 'ИУ', 1, 20),
       ('21', 'Студент21', 'ИУ', 1, 21),
       ('22', 'Студент22', 'ИУ', 1, 22),
       ('23', 'Студент23', 'ИУ', 1, 23),
       ('24', 'Студент24', 'ИУ', 1, 24);
;

insert into rk2_mark (number, gos_mark, diplom_mark)
values ('1', 5, 4),
       ('2', 4, 4),
       ('3', 3, 3),
       ('4', 4, 5),
       ('5', 4, 4),
       ('6', 3, 3),
       ('7', 5, 5),
       ('8', 3, 4),
       ('9', 3, 3),
       ('10', 5, 5),
       ('11', 4, 4),
       ('12', 3, 5),
       ('13', 4, 4),
       ('14', 4, 4),
       ('15', 3, 3),
       ('16', 5, 5),
       ('17', 3, 4),
       ('18', 2, 3),
       ('19', 5, 5),
       ('20', 4, 4),
       ('21', 3, 5),
       ('22', 4, 4),
       ('23', 4, 4),
       ('24', 2, 2);
;

-- task 2

-- Инструкция SELECT, использующая предикат сравнения с квантором.
-- Получить преподавателя, средняя оценка за экзамен+диплом студентов которого выше или равна 4
select te.fio, avg((mk.gos_mark + mk.diplom_mark) / 2.0) as avg_mark
from rk2_teacher as te
         join rk2_student st on te.id = st.id
         join rk2_mark mk on st.number = mk.number
group by te.fio
having avg((mk.gos_mark + mk.diplom_mark) / 2.0) >= 4;

-- Инструкция SELECT, использующая предикат BETWEEN.
-- Получить студентов, которые сдали диплом (минимум 3)
select st.fio, mk.diplom_mark
from rk2_student as st
         join rk2_mark mk on st.number = mk.number
where mk.diplom_mark between 3 and 5
order by mk.diplom_mark desc;

-- Инструкция с накопительной оконной функцией (SUM OVER).

with annotated_students as (
    select st.id,
    te.fio as teacher_fio,
    case when mk.gos_mark >= 4 and mk.diplom_mark >= 4 then 1
    else 0 end as is_good
    from rk2_student as st
        join rk2_mark mk on st.number = mk.number
        join rk2_teacher te on st.id = te.id)
select distinct teacher_fio,
    sum(is_good) over (partition by teacher_fio) as count_good_students -- вычисляем сумму is_good для каждого преподавателя
from annotated_students
order by teacher_fio;

-- task 3
-- Создать функцию, которая создает копии всех пользовательских таблиц из указанной схемы данных в базе данных.
-- Название схемы требуется передать в качестве параметра функции.
-- Имя таблиц-копий должно состоять из имени оригинальной таблицы и даты создания резервной копии, разделенных символом нижнего подчеркивания.
-- Дата создания резервной копии должна быть представлена в формате YYYYDDMM.

create or replace function copy_tables(schema_name text)
    returns void as
$$
declare
    table_name      text;
    copy_table_name text;
begin
    for table_name in
        select t.table_name
        from information_schema.tables t
        where t.table_schema = schema_name
        loop
            copy_table_name := table_name || '_' || to_char(current_date, 'YYYYDDMM');
            execute format('create table %I as select * from %I', copy_table_name, table_name);
        end loop;
end;
$$ language plpgsql;

-- Протестировать созданную функцию
select copy_tables('public');

-- получить список оригинальных таблиц без копий
select table_name
from information_schema.tables
WHERE table_schema = 'public'
  and table_name like 'rk2_%'
  and table_name not like 'rk2_%\_%';

-- получить список скопированных таблиц
select table_name
from information_schema.tables
WHERE table_schema = 'public'
  and table_name like 'rk2_%\_%';
