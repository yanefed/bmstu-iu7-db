import csv
import random

from faker import Faker

faker = Faker()


def generate_email():
    return faker.unique.email()


def generate_phone_number():
    return faker.unique.phone_number()


def generate_name():
    return f"{faker.last_name()} {faker.first_name()}"


def generate_rating():
    return random.randint(1, 5)


def generate_room_name():
    return faker.unique.color_name()


def generate_address():
    return faker.address()


def generate_price():
    return random.randint(200, 1000)


def generate_min_hours():
    return random.choice([1, 3])


def write_to_csv(filename, data, fieldnames):
    with open(filename, mode="w", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=fieldnames)
        writer.writeheader()
        for item in data:
            writer.writerow(item.__dict__)
