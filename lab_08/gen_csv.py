import csv
import os
import random
import time
from datetime import datetime

from faker import Faker

fake = Faker()

index = 0


def generate_customer_data(num_records, start_index):
    headers = ["customer_id", "name", "phone_number", "email", "ban"]
    data = []
    for i in range(num_records):
        data.append(
            [
                start_index + i,
                fake.name(),
                fake.phone_number(),
                fake.email(),
                random.choice(["true", "false"]),
            ]
        )

    return headers, data


def create_data_file(table_name, start_index):
    # Создаем директорию для файлов, если она не существует
    if not os.path.exists("nifi/in_file"):
        os.makedirs("nifi/in_file")

    # Получаем текущее время для имени файла
    current_time = datetime.now()
    file_id = random.randint(1000, 9999)

    # Формируем имя файла по маске
    filename = f"nifi/in_file/{file_id}_{table_name}_{current_time.strftime('%Y_%m_%d_%H:%M:%S')}.csv"

    # Генерируем случайное количество записей (от 5 до 10)
    num_records = random.randint(10, 100)
    headers, data = generate_customer_data(num_records, start_index)
    start_index += num_records

    with open(filename, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f, delimiter=";")
        writer.writerow(headers)
        writer.writerows(data)

    print(f"Created file: {filename}")
    return start_index


def main():
    start_index = 0

    while True:
        start_index = create_data_file("customer", start_index)

        # Ждем 5 минут
        print("Waiting 5 minutes before next generation...")
        time.sleep(300)


if __name__ == "__main__":
    main()
