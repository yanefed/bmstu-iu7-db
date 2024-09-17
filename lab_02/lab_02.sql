-- 1. Инструкция SELCT, использующая предикат сравнения.
SELECT ro.name, hour.hour
FROM postgres.public.hour
         JOIN public.room ro on ro.room_id = hour.room_id
WHERE date = '2024-09-01'
  and rehearsal_id IS NULL
ORDER BY ro.name, hour;


-- 2. Инструкция SELECT, использующая предикат BETWEEN.
SELECT re.rehearsal_id, ro.name, re.date, re.room_rate
FROM rehearsal re
         JOIN public.rehearsals_in_room rir on rir.rehearsal_id = re.rehearsal_id
         JOIN public.room ro on ro.room_id = rir.room_id
WHERE re.date BETWEEN '2024-08-01' AND '2024-08-14'
ORDER BY re.date;


-- 3. Инструкция SELECT, использующая предикат LIKE.
SELECT *
FROM postgres.public.room
WHERE name LIKE 'B%';


-- 4. Инструкция SELECT, использующая предикат IN с вложенным подзапросом.
SELECT *
FROM postgres.public.rehearsal
WHERE customer_id IN (SELECT customer_id FROM public.customer WHERE ban = true)
ORDER BY date;


-- 5. Инструкция SELECT, использующая предикат EXISTS с вложенным подзапросом.
SELECT *
FROM postgres.public.room ro
WHERE EXISTS (SELECT *
              FROM public.rehearsals_in_room rir
                       JOIN public.rehearsal re ON rir.rehearsal_id = re.rehearsal_id
              WHERE rir.room_id = ro.room_id
                AND re.customer_rate > 4)
ORDER BY ro.name;


-- 6. Инструкция SELECT, использующая предикат сравнения с квантором.
SELECT *
FROM postgres.public.rehearsal re
WHERE room_rate >= ALL (SELECT room_rate
                        FROM postgres.public.rehearsal
                        WHERE date = '2024-09-01')
ORDER BY room_rate DESC;


-- 7. Инструкция SELECT, использующая агрегатные функции в выражениях столбцов.
SELECT ro.name, avg(re.room_rate) as "avg_room_rate"
FROM postgres.public.room ro
         JOIN public.rehearsals_in_room rir on rir.room_id = ro.room_id
         JOIN public.rehearsal re on "re".rehearsal_id = rir.rehearsal_id
GROUP BY ro.name
ORDER BY "avg_room_rate" DESC;


-- 8. Инструкция SELECT, использующая скалярные подзапросы в выражениях столбцов.
SELECT ro.name,
       (SELECT count(*)
        FROM public.rehearsals_in_room rir
                 JOIN public.rehearsal re on rir.rehearsal_id = re.rehearsal_id
        WHERE rir.room_id = ro.room_id) as "rehearsals_count"
FROM postgres.public.room ro
ORDER BY ro.name;


-- 9. Инструкция SELECT, использующая простое выражение CASE.
SELECT cu.name,
       ro.name,
       CASE
           WHEN re.date = now()::date THEN 'today'
           WHEN re.date = now()::date - interval '1 day' THEN 'yesterday'
           WHEN re.date = now()::date + interval '1 day' THEN 'tomorrow'
           ELSE re.date::text
           END as date_hum
FROM postgres.public.rehearsal re
         JOIN public.customer cu on cu.customer_id = re.customer_id
         JOIN public.rehearsals_in_room rir on rir.rehearsal_id = re.rehearsal_id
         JOIN public.room ro on ro.room_id = rir.room_id
WHERE re.date BETWEEN now()::date - interval '2 day' AND now()::date + interval '2 day';


-- 10. Инструкция SELECT, использующая поисковое выражение CASE.
SELECT ro.name,
       CASE
           WHEN ro.price_per_hour < 300 THEN 'cheap'
           WHEN ro.price_per_hour < 500 THEN 'normal'
           ELSE 'expensive'
           END as price_category
FROM postgres.public.room ro
ORDER BY ro.name;


-- 11. Создание новой временной локальной таблицы из результирующего набора данных инструкции SELECT.
SELECT date_trunc('month', re.date) as month, r.name, count(re.rehearsal_id)
INTO TEMPORARY "month_results"
FROM postgres.public.rehearsal re
         JOIN public.rehearsals_in_room rir on rir.rehearsal_id = re.rehearsal_id
         JOIN public.room r on r.room_id = rir.room_id
GROUP BY month, r.name
ORDER BY month;

SELECT *
FROM "month_results";

DROP TABLE IF EXISTS "month_results";


-- 12. Инструкция SELECT, использующая вложенные коррелированные подзапросы в качестве производных таблиц в предложении FROM.
SELECT re.date, h.start_hour, h.end_hour, h.total_hours
FROM postgres.public.rehearsal re
         JOIN (SELECT rehearsal_id, count(hour_id) as total_hours, min(hour) as start_hour, max(hour) as end_hour
               FROM postgres.public.hour
               WHERE room_id = 1
               GROUP BY rehearsal_id) h ON re.rehearsal_id = h.rehearsal_id
         JOIN public.customer c on c.customer_id = re.customer_id
ORDER BY re.date, h.start_hour;


-- 13. Инструкция SELECT, использующая вложенные подзапросы с уровнем вложенности 3.
SELECT ro.name,
       (SELECT COUNT(*)
        FROM public.rehearsals_in_room rir
        WHERE rir.room_id = ro.room_id
          AND rir.rehearsal_id IN (SELECT re.rehearsal_id
                                   FROM public.rehearsal re
                                   WHERE re.customer_id IN (SELECT cu.customer_id
                                                            FROM public.customer cu
                                                            WHERE cu.ban = false)))
FROM postgres.public.room ro
ORDER BY ro.name;


-- 14. Инструкция SELECT, консолидирующая данные с помощью предложения GROUP BY, но без предложения HAVING.
SELECT ro.name, count(re.rehearsal_id) AS total_rehearsals
FROM postgres.public.room ro
         JOIN public.rehearsals_in_room rir ON ro.room_id = rir.room_id
         JOIN public.rehearsal re ON re.rehearsal_id = rir.rehearsal_id
WHERE re.date BETWEEN '2024-08-01' AND '2024-08-31'
GROUP BY ro.name
ORDER BY total_rehearsals DESC;


-- 15. Инструкция SELECT, консолидирующая данные с помощью предложения GROUP BY и предложения HAVING.
SELECT ro.name, count(re.rehearsal_id) AS total_rehearsals, avg(re.room_rate) as avg_room_rate
FROM postgres.public.room ro
         JOIN public.rehearsals_in_room rir ON ro.room_id = rir.room_id
         JOIN public.rehearsal re ON re.rehearsal_id = rir.rehearsal_id
WHERE re.date BETWEEN '2024-08-01' AND '2024-08-31'
GROUP BY ro.name
HAVING avg(re.room_rate) > 3
ORDER BY total_rehearsals DESC;


-- 16. Однострочная инструкция INSERT, выполняющая вставку в таблицу одной строки значений.
INSERT INTO customer (name, phone_number, email, ban)
VALUES ('Ivan Bogatyrev', '+79067072241', 'yane@qevm.tech', false);


-- 17. Многострочная инструкция INSERT, выполняющая вставку в таблицу результирующего набора данных вложенного подзапроса.
INSERT INTO rehearsal (date, customer_id, customer_rate, room_rate, additional_info)
SELECT date, customer_id, 1, 5, 'test'
FROM public.rehearsal
WHERE room_rate = 1
  AND customer_rate = 1;

SELECT *
FROM public.rehearsal
WHERE additional_info = 'test';

DELETE
FROM public.rehearsal
WHERE additional_info = 'test';


-- 18. Простая инструкция UPDATE.
UPDATE postgres.public.rehearsal
SET room_rate = room_rate + 2
WHERE room_rate < 3;


-- 19. Инструкция UPDATE со скалярным подзапросом в предложении SET.
UPDATE postgres.public.rehearsal
SET room_rate = (SELECT AVG(room_rate)
                 FROM postgres.public.rehearsal
                 WHERE customer_id = rehearsal.customer_id)
WHERE customer_id IN (SELECT customer_id FROM public.customer WHERE ban = true);


-- 20. Простая инструкция DELETE.
DELETE
FROM postgres.public.hour
WHERE date < now()::date - interval '14 day'
  and rehearsal_id IS NULL;


-- 21. Инструкция DELETE с вложенным коррелированным подзапросом в предложении WHERE.
DELETE
FROM postgres.public.hour
WHERE rehearsal_id IN (SELECT rehearsal_id
                       FROM postgres.public.rehearsal
                       WHERE customer_id IN (SELECT customer_id FROM public.customer WHERE ban = true));

DELETE
FROM postgres.public.rehearsals_in_room
WHERE rehearsal_id IN (SELECT rehearsal_id
                       FROM postgres.public.rehearsal
                       WHERE customer_id IN (SELECT customer_id FROM public.customer WHERE ban = true));

DELETE
FROM postgres.public.rehearsal
WHERE customer_id IN (SELECT customer_id FROM public.customer WHERE ban = true);


-- 22. Инструкция SELECT, использующая простое обобщенное табличное выражение
WITH CTE (customer_id, avg_rate) AS (SELECT customer_id, avg(room_rate)
                                     FROM postgres.public.rehearsal
                                     GROUP BY customer_id)
SELECT c.name, cte.avg_rate
FROM postgres.public.customer c
         JOIN CTE ON c.customer_id = CTE.customer_id
ORDER BY cte.avg_rate DESC;


-- 23. Инструкция SELECT, использующая рекурсивное обобщенное табличное выражение.
-- Создание таблицы.
CREATE TABLE Staff
(
    EmployeeID serial primary key,
    FirstName  text,
    LastName   text,
    Title      text,
    ManagerID  int
);

INSERT INTO Staff
VALUES (1, N'Иван', N'Петров', N'Главный исполнительный директор', NULL),
       (2, N'Алексей', N'Сидоров', N'Исполнительный директор', 1),
       (3, N'Андрей', N'Иванов', N'Менеджер', 2),
       (4, N'Сергей', N'Смирнов', N'Менеджер', 2),
       (5, N'Александр', N'Кузнецов', N'Менеджер', 2),
       (6, N'Антон', N'Попов', N'Менеджер', 2),
       (7, N'Дмитрий', N'Васильев', N'Администратор', 3),
       (8, N'Алексей', N'Петров', N'Администратор', 3),
       (9, N'Андрей', N'Сидоров', N'Администратор', 4),
       (10, N'Сергей', N'Иванов', N'Администратор', 4),
       (11, N'Александр', N'Смирнов', N'Администратор', 5),
       (12, N'Антон', N'Кузнецов', N'Администратор', 5),
       (13, N'Дмитрий', N'Попов', N'Администратор', 6),
       (14, N'Алексей', N'Васильев', N'Администратор', 6),
       (15, N'Андрей', N'Петров', N'Администратор', 3),
       (16, N'Сергей', N'Сидоров', N'Администратор', 4)
;

-- Рекурсивное обобщенное табличное выражение для вычисления иерархии сотрудников
WITH RECURSIVE StaffHierarchy AS (
    -- Начальное значение рекурсии
    SELECT EmployeeID, FirstName, LastName, Title, ManagerID, 1 AS Level
    FROM Staff
    WHERE ManagerID IS NULL

    UNION ALL

    SELECT s.EmployeeID, s.FirstName, s.LastName, s.Title, s.ManagerID, sh.Level + 1
    FROM Staff s
             JOIN StaffHierarchy sh ON s.ManagerID = sh.EmployeeID)
SELECT EmployeeID, FirstName, LastName, Title, ManagerID, Level
FROM StaffHierarchy
ORDER BY Level, ManagerID, EmployeeID;

DROP TABLE IF EXISTS Staff;

-- 24. Оконные функции. Использование конструкций MIN/MAX/AVG OVER()
SELECT re.date,
       re.room_rate,
       MIN(re.room_rate) OVER (PARTITION BY re.date) as min_room_rate,
       MAX(re.room_rate) OVER (PARTITION BY re.date) as max_room_rate,
       AVG(re.room_rate) OVER (PARTITION BY re.date) as avg_room_rate
FROM postgres.public.rehearsal re
ORDER BY re.date, re.room_rate;


-- 25. Оконные функции для устранения дублей.
-- Придумать запрос, в результате которого в данных появляются полные дубли.
-- Устранить дублирующиеся строки с использованием функции ROW_NUMBER().

CREATE TABLE IF NOT EXISTS customer_dupl
(
    customer_id  serial primary key,
    name         text,
    phone_number text,
    email        text,
    ban          boolean
);

INSERT INTO customer_dupl (name, phone_number, email, ban)
SELECT name, phone_number, email, ban
FROM public.customer;

SELECT name, phone_number, email, ban, row_number() over (partition by name, phone_number, email, ban) as rn
FROM customer_dupl
ORDER BY name, phone_number, email, ban;

SELECT name, phone_number, email, ban
FROM (SELECT name, phone_number, email, ban, row_number() over (partition by name, phone_number, email, ban) as rn
      FROM customer_dupl) as t
WHERE rn = 1;

DELETE
FROM customer_dupl
WHERE customer_id NOT IN (SELECT customer_id
                          FROM (SELECT customer_id,
                                       row_number() over (partition by name, phone_number, email, ban) as rn
                                FROM customer_dupl) as t
                          WHERE rn = 1);

DROP TABLE IF EXISTS customer_dupl;