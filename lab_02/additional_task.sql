-- Создать таблицы:
-- Table1{id: integer, var1: string, valid_from_dttm: date, valid_to_dttm: date}
-- Table2{id: integer, var2: string, valid_from_dttm: date, valid_to_dttm: date}
-- Версионность в таблицах непрерывная, разрывов нет (если valid_to_dttm =
-- '2018-09-05', то для следующей строки соответствующего ID valid_from_dttm =
-- '2018-09-06', т.е. на день больше). Для каждого ID дата начала версионности и
-- дата конца версионности в Table1 и Table2 совпадают.
-- Выполнить версионное соединение двух талиц по полю id

CREATE TABLE IF NOT EXISTS Table1
(
    id              int,
    var1            text,
    valid_from_dttm date,
    valid_to_dttm   date
);

CREATE TABLE IF NOT EXISTS Table2
(
    id              int,
    var2            text,
    valid_from_dttm date,
    valid_to_dttm   date
);

INSERT INTO Table1 (id, var1, valid_from_dttm, valid_to_dttm)
VALUES (1, 'A', '2018-09-01', '2018-09-15'),
       (1, 'B', '2018-09-16', '2018-10-31'),
       (1, 'C', '2018-11-01', '5999-12-31');

INSERT INTO Table2 (id, var2, valid_from_dttm, valid_to_dttm)
VALUES (1, 'A', '2018-09-01', '2018-09-18'),
       (1, 'B', '2018-09-19', '5999-12-31');

SELECT *
FROM Table1
UNION ALL
SELECT *
FROM Table2;


SELECT t1.id,
       t1.var1,
       t2.var2,
       GREATEST(t1.valid_from_dttm, t2.valid_from_dttm) AS valid_from_dttm,
       LEAST(t1.valid_to_dttm, t2.valid_to_dttm)        AS valid_to_dttm
FROM Table1 t1
         JOIN Table2 t2
              ON t1.id = t2.id
ORDER BY valid_from_dttm;


SELECT t1.id,
       t1.var1,
       t2.var2,
       GREATEST(t1.valid_from_dttm, t2.valid_from_dttm) AS valid_from_dttm,
       LEAST(t1.valid_to_dttm, t2.valid_to_dttm)        AS valid_to_dttm
FROM Table1 t1
         JOIN Table2 t2
              ON t1.id = t2.id
                  AND GREATEST(t1.valid_from_dttm, t2.valid_from_dttm) < LEAST(t1.valid_to_dttm, t2.valid_to_dttm)
ORDER BY t1.id, valid_from_dttm;


DROP TABLE Table1;
DROP TABLE Table2;