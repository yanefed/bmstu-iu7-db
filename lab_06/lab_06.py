"""
Целью лабораторной работы является приобретение практических навыков
подключения к базе данных и выполнению запросов из приложения.
Задание
Разработать консольное приложение с меню, состоящее из 10 функций,
демонстрирующих основные приемы работы с базой данных. Все запросы,
функции и процедуры должны выполняться на стороне базы данных:

1. Выполнить скалярный запрос;
2. Выполнить запрос с несколькими соединениями (JOIN);
3. Выполнить запрос с ОТВ(CTE) и оконными функциями;
4. Выполнить запрос к метаданным;
5. Вызвать скалярную функцию (написанную в третьей лабораторной работе);
6. Вызвать многооператорную или табличную функцию (написанную в третьей лабораторной работе);
7. Вызвать хранимую процедуру (написанную в третьей лабораторной работе);
8. Вызвать системную функцию или процедуру;
9. Создать таблицу в базе данных, соответствующую тематике БД;
10. Выполнить вставку данных в созданную таблицу с использованием инструкции INSERT или COP
"""
import datetime
import os

import psycopg2

# Подключение к базе данных
conn = psycopg2.connect(
    dbname="postgres",
    user="yane",
    password=os.getenv("POSTGRES_PASSWORD"),
    host="localhost",
)
cursor = conn.cursor()


def print_menu():
    print("1. Выполнить скалярный запрос")
    print("2. Выполнить запрос с несколькими соединениями (JOIN)")
    print("3. Выполнить запрос с ОТВ(CTE) и оконными функциями")
    print("4. Выполнить запрос к метаданным")
    print("5. Вызвать скалярную функцию")
    print("6. Вызвать многооператорную или табличную функцию")
    print("7. Вызвать хранимую процедуру")
    print("8. Вызвать системную функцию или процедуру")
    print("9. Создать таблицу в базе данных")
    print("10. Выполнить вставку данных в созданную таблицу")
    print("0. Выход")


def scalar_query():
    cursor.execute("SELECT COUNT(*) FROM customer")
    result = cursor.fetchone()
    print("Количество клиентов:", result[0])
    print()


def join_query():
    cursor.execute(
        """
    SELECT ro.name, avg(re.room_rate) as "avg_room_rate" 
    FROM postgres.public.room ro 
    JOIN rehearsals_in_room rir on rir.room_id = ro.room_id 
    JOIN rehearsal re on "re".rehearsal_id = rir.rehearsal_id 
    GROUP BY ro.name 
    ORDER BY "avg_room_rate" DESC;
    """
    )
    result = cursor.fetchall()
    print("Средняя оценка комнат:")
    print("name\t|\tavg_room_rate")
    for row in result:
        print(f"{row[0]}\t|\t{row[1]}")
    print()


def cte_query():
    cursor.execute(
        """
        WITH CTE (customer_id, avg_rate) AS (
            SELECT customer_id, avg(room_rate)
            FROM postgres.public.rehearsal
            GROUP BY customer_id
        )
        SELECT c.name, cte.avg_rate
        FROM postgres.public.customer c
            JOIN CTE ON c.customer_id = CTE.customer_id
        ORDER BY cte.avg_rate DESC;
    """
    )
    result = cursor.fetchall()
    print("Средняя оценка, оставленная клиентом:")
    print("name\t|\tavg_rate")
    for row in result:
        print(f"{row[0]}\t|\t{row[1]}")
    print()


def metadata_query():
    cursor.execute(
        """
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
    ORDER BY table_name;
    """
    )
    result = cursor.fetchall()
    print("Таблицы в базе данных:")
    print("table_name")
    for row in result:
        print(f"{row[0]}")
        cursor.execute(
            """
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_name = 'rehearsal'
        ORDER BY ordinal_position;
        """
        )
        columns_types = cursor.fetchall()
        print(f"Типы данных столбцов таблицы {row[0]}:")
        print(f"{('column_name').ljust(15)}\t|\tdata_type")
        for row in columns_types:
            print(f"{str(row[0]).ljust(15)}\t|\t{row[1]}")
        print()
    print()


def call_scalar_function():
    rehearsal_id = int(input("Введите id репетиции: "))
    cursor.execute(f"SELECT public.get_last_hour_of_rehearsal({rehearsal_id})")
    result = cursor.fetchone()
    print(f"Последний час репетиции {rehearsal_id}: ", result[0])
    print()


def call_table_function():
    customer_id = int(input("Введите id клиента: "))
    cursor.execute(f"SELECT * FROM public.get_rehearsals_of_customer({customer_id})")
    result = cursor.fetchall()
    print("Репетиции клиента:")
    print("rehearsal_id\t|\troom_id\t|\troom_rate\t|\tstart_time\t|\tend_time")
    for row in result:
        print(f"{row[0]}\t|\t{row[1]}\t|\t{row[2]}\t|\t{row[3]}\t|\t{row[4]}")
    print()


def call_procedure():
    today = datetime.date.today()
    cursor.execute(f"CALL public.clear_unused_hours('{today}')")
    print("Процедура выполнена\n")


def call_system_function():
    cursor.execute("SELECT version()")
    result = cursor.fetchone()
    print("Версия PostgreSQL:", result[0])
    print()


def create_table():
    cursor.execute(
        """
    CREATE TABLE IF NOT EXISTS public.places
    (
        id SERIAL PRIMARY KEY,
        name text NOT NULL,
        address text NOT NULL,
        employees json NOT NULL
    );
    """
    )
    print("Таблица создана\n")


def insert_data():
    # проверка существования таблицы
    cursor.execute(
        """
    SELECT EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'places'
    );
    """
    )
    result = cursor.fetchone()
    if not result[0]:
        print("Таблица не существует")
        return
    cursor.execute(
        """
    INSERT INTO public.places (name, address, employees)
    VALUES ('Company1', 'Address1', '[{"name": "Administrator", "position": "Master"}, {"name": "Trainee", "position": "Trainee"}]');
    """
    )
    print("Данные вставлены\n")


actions = [
    None,
    scalar_query,
    join_query,
    cte_query,
    metadata_query,
    call_scalar_function,
    call_table_function,
    call_procedure,
    call_system_function,
    create_table,
    insert_data,
]


def main():
    while True:
        print_menu()
        choice = input("Выберите пункт меню: ")
        if choice == "0":
            break
        elif choice.isdigit() and 1 <= int(choice) <= 10:
            actions[int(choice)]()
        else:
            print("Неверный пункт меню")


if __name__ == "__main__":
    main()
    cursor.close()
    conn.close()
