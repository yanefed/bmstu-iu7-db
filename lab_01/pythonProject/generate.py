import concurrent.futures
import itertools
import sys

from dateutil.utils import today

from models import *
from utils import *

sys.setrecursionlimit(1000000)

customers_limit = 1000
rooms_limit = 50
current_year = datetime.datetime.now().year
start_date = datetime.datetime(current_year, 8, 1)
today_date = datetime.datetime.today()


def generate_customer():
    return [
        Customer(
            customer_id=i,
            name=generate_name(),
            phone_number=generate_phone_number(),
            email=generate_email(),
            ban=False,
        )
        for i in range(customers_limit)
    ]


def generate_rooms():
    return [
        Room(
            room_id=i,
            name=generate_room_name(),
            address=generate_address(),
            price_per_hour=generate_price(),
            min_hours=generate_min_hours(),
        )
        for i in range(rooms_limit)
    ]


def generate_hours_for_year(rooms, start_date=start_date):
    end_date = datetime.datetime(current_year + 1, 1, 1)
    delta = datetime.timedelta(days=1)

    hours = []
    hour_id = 0

    while start_date < end_date:
        for room in rooms:
            for hour in range(24):
                hours.append(
                    Hour(
                        hour_id=hour_id,
                        room_id=room.room_id,
                        date=start_date,
                        hour=hour,
                        available=start_date > today_date,
                    )
                )
                hour_id += 1
        start_date += delta

    return hours


rehearsal_id_counter = (
    itertools.count()
)  # Глобальный счетчик для уникальных rehearsal_id
rehearsal_hour_id_counter = (
    itertools.count()
)  # Глобальный счетчик для уникальных rehearsal_hour_id
rehearsal_room_id_counter = (
    itertools.count()
)  # Глобальный счетчик для уникальных rehearsal_room_id


def generate_rehearsals_for_room(room, customers, hours, start_date, end_date):
    rehearsals = []
    rehearsal_hours = []
    rehearsal_rooms = []
    delta = datetime.timedelta(days=1)

    while start_date < end_date:
        occupied_hours = set()
        for _ in range(len(customers)):  # Количество репетиций в день
            customer = random.choice(customers)
            status = random.choice([1, 2, 3])
            paid = random.choice([True, False])

            # Дневные репетиции (с 9 утра до полуночи)
            day_hours = list(range(9, 24))
            while day_hours:
                duration = random.randint(1, 6)
                start_hour = random.choice(day_hours)
                end_hour = min(start_hour + duration, 24)
                rehearsal_hours_range = list(range(start_hour, end_hour))

                if not any(hour in occupied_hours for hour in rehearsal_hours_range):
                    rehearsals.append(
                        Rehearsal(
                            rehearsal_id=next(rehearsal_id_counter),
                            customer_id=customer.customer_id,
                            date=start_date,
                            customer_rate=generate_rating(),
                            room_rate=generate_rating(),
                            status=status,
                        )
                    )
                    for hour in rehearsal_hours_range:
                        rehearsal_hours.append(
                            RehearsalHour(
                                id=next(rehearsal_hour_id_counter),
                                rehearsal_id=rehearsals[-1].rehearsal_id,
                                hour_id=next(
                                    h.hour_id
                                    for h in hours
                                    if h.room_id == room.room_id
                                    and h.date == start_date
                                    and h.hour == hour
                                ),
                            )
                        )
                        occupied_hours.add(hour)
                    rehearsal_rooms.append(
                        RehearsalRoom(
                            id=next(rehearsal_room_id_counter),
                            rehearsal_id=rehearsals[-1].rehearsal_id,
                            room_id=room.room_id,
                            paid=paid,
                        )
                    )

                day_hours = [hour for hour in day_hours if hour not in occupied_hours]

        start_date += delta

    return rehearsals, rehearsal_hours, rehearsal_rooms


def generate_rehearsals(customers, rooms, hours, start_date):
    all_rehearsals = []
    all_rehearsal_hours = []
    all_rehearsal_rooms = []

    with concurrent.futures.ThreadPoolExecutor() as executor:
        futures = [
            executor.submit(
                generate_rehearsals_for_room,
                room,
                customers,
                hours,
                start_date,
                today_date,
            )
            for room in rooms
        ]
        for future in concurrent.futures.as_completed(futures):
            rehearsals, rehearsal_hours, rehearsal_rooms = future.result()
            all_rehearsals.extend(rehearsals)
            all_rehearsal_hours.extend(rehearsal_hours)
            all_rehearsal_rooms.extend(rehearsal_rooms)

    return all_rehearsals, all_rehearsal_hours, all_rehearsal_rooms


rooms = generate_rooms()
print("Rooms generated")
hours = generate_hours_for_year(rooms)
print("Hours generated")
customers = generate_customer()
print("Customers generated")
rehearsals, rehearsal_hours, rehearsal_rooms = generate_rehearsals(
    customers, rooms, hours, start_date
)
print("Rehearsals generated")
print("Writing to CSV files...")
write_to_csv(
    "customers.csv", customers, ["customer_id", "name", "phone_number", "email", "ban"]
)
print("Customers - done")
write_to_csv(
    "rooms.csv", rooms, ["room_id", "name", "address", "price_per_hour", "min_hours"]
)
print("Rooms - done")
write_to_csv("hours.csv", hours, ["hour_id", "room_id", "date", "hour", "available"])
print("Hours - done")
write_to_csv(
    "rehearsals.csv",
    rehearsals,
    ["rehearsal_id", "customer_id", "date", "customer_rate", "room_rate", "status"],
)
print("Rehearsals - done")
write_to_csv("rehearsal_hours.csv", rehearsal_hours, ["id", "rehearsal_id", "hour_id"])
write_to_csv(
    "rehearsal_rooms.csv", rehearsal_rooms, ["id", "rehearsal_id", "room_id", "paid"]
)
print("Files written successfully")
