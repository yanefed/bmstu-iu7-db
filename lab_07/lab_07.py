import json
import os

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Column,
    create_engine,
    Date,
    extract,
    ForeignKey,
    ForeignKeyConstraint,
    func,
    Integer,
    Text,
    text,
    UniqueConstraint,
)
from sqlalchemy.orm import declarative_base, relationship, sessionmaker

user = os.getenv("POSTGRES_USER", "postgres")
password = os.getenv("POSTGRES_PASSWORD", "password")
host = os.getenv("POSTGRES_HOST", "localhost")
port = os.getenv("POSTGRES_PORT", "5432")
database = os.getenv("POSTGRES_DB", "postgres")

engine = create_engine(f"postgresql://{user}:{password}@{host}:{port}/{database}")
Base = declarative_base()


# Модели таблиц
class Room(Base):
    __tablename__ = "room"

    room_id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(Text, nullable=False)
    address = Column(Text, nullable=False)
    price_per_hour = Column(Integer, nullable=False)
    min_hours = Column(Integer, nullable=False)

    # Связь M2M с Rehearsal
    rehearsals = relationship(
        "Rehearsal", secondary="rehearsals_in_room", back_populates="rooms"
    )
    hours = relationship("Hour", back_populates="room")

    __table_args__ = (
        CheckConstraint("name != ''", name="valid_name"),
        CheckConstraint("address != ''", name="valid_address"),
        CheckConstraint("price_per_hour >= 0", name="valid_pph"),
        CheckConstraint("min_hours >= 0", name="valid_hours"),
        UniqueConstraint("name", name="unique_name"),
    )

    def __repr__(self):
        return f"<Room(name='{self.name}', address='{self.address}')>"


class Customer(Base):
    __tablename__ = "customer"

    customer_id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(Text, nullable=False)
    phone_number = Column(Text)
    email = Column(Text)
    ban = Column(Boolean, default=False)

    rehearsals = relationship("Rehearsal", back_populates="customer")

    __table_args__ = (
        CheckConstraint("name != ''", name="valid_name"),
        CheckConstraint("phone_number != ''", name="valid_phone_number"),
        CheckConstraint("email != ''", name="valid_email"),
        UniqueConstraint("phone_number", name="unique_phone_number"),
        UniqueConstraint("email", name="unique_email"),
    )

    def __repr__(self):
        return f"<Customer(name='{self.name}', email='{self.email}')>"


class Hour(Base):
    __tablename__ = "hour"

    hour_id = Column(Integer, primary_key=True, autoincrement=True)
    room_id = Column(Integer, ForeignKey("room.room_id"), nullable=False)
    rehearsal_id = Column(Integer, ForeignKey("rehearsal.rehearsal_id"), nullable=True)
    date = Column(Date, nullable=False)
    hour = Column(Integer, nullable=False)

    room = relationship("Room", back_populates="hours")
    rehearsal = relationship("Rehearsal", back_populates="hours")

    __table_args__ = (
        ForeignKeyConstraint(["room_id"], ["room.room_id"], name="fk_room_id"),
        ForeignKeyConstraint(
            ["rehearsal_id"], ["rehearsal.rehearsal_id"], name="fk_rehearsal_id"
        ),
        CheckConstraint("hour >= 0 AND hour < 24", name="valid_hour"),
    )

    def __repr__(self):
        return f"<Hour(room_id={self.room_id}, date='{self.date}', hour={self.hour})>"


class Rehearsal(Base):
    __tablename__ = "rehearsal"
    rehearsal_id = Column(Integer, primary_key=True, autoincrement=True)
    date = Column(Date, nullable=False)
    customer_id = Column(Integer, ForeignKey("customer.customer_id"), nullable=False)
    customer_rate = Column(Integer)
    room_rate = Column(Integer)
    additional_info = Column(Text)

    customer = relationship("Customer", back_populates="rehearsals")
    hours = relationship("Hour", back_populates="rehearsal")
    rooms = relationship(
        "Room", secondary="rehearsals_in_room", back_populates="rehearsals"
    )

    __table_args__ = (
        ForeignKeyConstraint(
            ["customer_id"], ["customer.customer_id"], name="fk_customer_id"
        ),
        CheckConstraint(
            "customer_rate > 0 AND customer_rate <= 5", name="valid_customer_rate"
        ),
        CheckConstraint("room_rate > 0 AND room_rate <= 5", name="valid_room_rate"),
        CheckConstraint("additional_info != ''", name="valid_info"),
    )

    def __repr__(self):
        return f"<Rehearsal(date='{self.date}', customer_id={self.customer_id})>"


class RehearsalsInRoom(Base):
    __tablename__ = "rehearsals_in_room"

    id = Column(Integer, primary_key=True, autoincrement=True)
    rehearsal_id = Column(Integer, ForeignKey("rehearsal.rehearsal_id"), nullable=False)
    room_id = Column(Integer, ForeignKey("room.room_id"), nullable=False)
    status = Column(Integer, nullable=False)

    __table_args__ = (
        ForeignKeyConstraint(
            ["rehearsal_id"], ["rehearsal.rehearsal_id"], name="fk_rehearsal_id"
        ),
        ForeignKeyConstraint(["room_id"], ["room.room_id"], name="fk_room_id"),
        CheckConstraint("-1 <= status AND status <= 3", name="valid_status"),
    )

    def __repr__(self):
        return f"<RehearsalsInRoom(rehearsal_id={self.rehearsal_id}, room_id={self.room_id}, status={self.status})>"


# Создание таблиц
Base.metadata.create_all(engine)

# Настройка сессии
Session = sessionmaker(bind=engine)
session = Session()


# 1. Список клиентов с количеством репетиций, упорядоченный по убыванию количества, с фильтром по минимальному количеству репетиций
def query_1(minimal_rehearsals: int = 2, limit: int = 10):
    result = (
        session.query(
            Customer.name.label("customer_name"),
            func.count(Rehearsal.rehearsal_id).label("rehearsal_count"),
        )
        .join(Rehearsal, Customer.customer_id == Rehearsal.customer_id)
        .group_by(Customer.name)
        .having(func.count(Rehearsal.rehearsal_id) > minimal_rehearsals)
        .order_by(func.count(Rehearsal.rehearsal_id).desc())
        .limit(limit)
        .all()
    )

    # Вывод результата
    print(
        "Список клиентов с количеством репетиций, упорядоченный по убыванию количества, с фильтром по минимальному количеству репетиций"
    )
    for row in result:
        print(f"Customer: {row.customer_name}, Rehearsals: {row.rehearsal_count}")


# 2. Репетиции с привязкой к комнатам и клиентам, которые были забронированы в определённый месяц, с сортировкой и ограничением
def query_2(month_number: int = 9, limit: int = 10):
    result = (
        session.query(
            Rehearsal.date,
            Room.name.label("room_name"),
            Customer.name.label("customer_name"),
        )
        .join(
            RehearsalsInRoom, Rehearsal.rehearsal_id == RehearsalsInRoom.rehearsal_id
        )  # JOIN 1
        .join(Room, RehearsalsInRoom.room_id == Room.room_id)
        .join(Customer, Rehearsal.customer_id == Customer.customer_id)
        .filter(extract("month", Rehearsal.date) == month_number)
        .order_by(Rehearsal.date.asc())
        .limit(limit)
        .all()
    )

    print(
        "Репетиции с привязкой к комнатам и клиентам, которые были забронированы в определённый месяц, с сортировкой и ограничением"
    )
    for row in result:
        print(f"Date: {row.date}, Room: {row.room_name}, Customer: {row.customer_name}")


# 3. Список комнат с общей суммой заработанных денег, отсортированный по убыванию
def query_3(limit: int = 10):
    result = (
        session.query(
            Room.name.label("room_name"),
            func.sum(Room.price_per_hour * Hour.hour).label("total_income"),
        )
        .join(Hour, Room.room_id == Hour.room_id)
        .group_by(Room.name)
        .having(func.sum(Room.price_per_hour * Hour.hour) > 1000)
        .order_by(func.sum(Room.price_per_hour * Hour.hour).desc())
        .limit(limit)
        .all()
    )

    print(
        "Список комнат с общей суммой заработанных денег, отсортированный по убыванию"
    )
    for row in result:
        print(f"Room: {row.room_name}, Income: {row.total_income} rub")


# 4. Клиенты, которые бронировали более одной комнаты за всё время
def query_4(limit: int = 10):
    result = (
        session.query(
            Customer.name.label("customer_name"),
            func.count(func.distinct(RehearsalsInRoom.room_id)).label("room_count"),
        )
        .join(Rehearsal, Customer.customer_id == Rehearsal.customer_id)
        .join(RehearsalsInRoom, Rehearsal.rehearsal_id == RehearsalsInRoom.rehearsal_id)
        .group_by(Customer.name)
        .having(func.count(func.distinct(RehearsalsInRoom.room_id)) > 1)  # HAVING
        .order_by(Customer.name)
        .limit(limit)
        .all()
    )

    print("Клиенты, которые бронировали более одной комнаты за всё время")
    for row in result:
        print(f"Customer: {row.customer_name}, Rooms Booked: {row.room_count}")


# 5. Список всех доступных часов в каждой комнате за определённый день
def query_5(date: str = "2024-12-01", limit: int = 10):
    # Запрос
    result = (
        session.query(Room.name.label("room_name"), Hour.date, Hour.hour)
        .join(Hour, Room.room_id == Hour.room_id)
        .filter(Hour.date == date)
        .filter(Hour.rehearsal_id == None)  # Часы, не привязанные к репетициям
        .order_by(Room.name, Hour.hour)
        .distinct()
        .limit(limit)
        .all()
    )

    print("Список всех доступных часов в каждой комнате за определённый день")
    for row in result:
        print(f"Room: {row.room_name}, Date: {row.date}, Hour: {row.hour}")


def read_json(file_path):
    with open(file_path, "r") as file:
        return json.load(file)


def write_json(file_path, data):
    with open(file_path, "w") as file:
        json.dump(data, file, indent=4)


def query_and_save_to_json():
    # Получаем список комнат
    result = session.query(Room.name, Room.address).all()

    # Преобразуем результат в список словарей
    rooms_data = [{"name": name, "address": address} for name, address in result]

    # Сохраняем данные в JSON файл
    write_json("rooms_data.json", rooms_data)


def update_json_data(file_path, update_data):
    data = read_json(file_path)

    exists = False

    for item in data:
        if item["name"] == update_data["name"]:
            item.update(update_data)
            exists = True

    if not exists:
        data.append(update_data)

    write_json(file_path, data)


def one_table():
    result = session.query(Customer).all()
    print("Все клиенты:")
    for customer in result:
        print(f"ID: {customer.customer_id}, Name: {customer.name}")


def many_table():
    result = (
        session.query(
            Rehearsal.date,
            Room.name.label("room_name"),
            Customer.name.label("customer_name"),
        )
        .join(RehearsalsInRoom, Rehearsal.rehearsal_id == RehearsalsInRoom.rehearsal_id)
        .join(Room, RehearsalsInRoom.room_id == Room.room_id)
        .join(Customer, Rehearsal.customer_id == Customer.customer_id)
        .all()
    )
    print("Репетиции с привязкой к комнатам и клиентам:")
    for row in result:
        print(f"Date: {row.date}, Room: {row.room_name}, Customer: {row.customer_name}")


def insert_data():
    new_customer = Customer(
        name="John Doe", phone_number="1234567890", email="john.doe@example.com"
    )
    session.add(new_customer)
    session.commit()
    print("New customer added.")


def update_data():
    customer = session.query(Customer).filter_by(name="John Doe").first()
    if customer:
        customer.email = "john.updated@example.com"
        session.commit()
        print("Customer email updated.")


def delete_data():
    customer = session.query(Customer).filter_by(name="John Doe").first()
    if customer:
        session.delete(customer)
        session.commit()
        print("Customer deleted.")


def execute_stored_procedure():
    session.execute(text("CALL add_hours_for_day()"))
    print("Stored procedure executed.")


def main():
    print("Select menu item:")
    print(
        "1. List of customers with the number of rehearsals, ordered by the number of rehearsals in descending order, with a filter by the minimum number of rehearsals"
    )
    print(
        "2. Rehearsals with binding to rooms and customers that were booked in a certain month, with sorting and limitation"
    )
    print(
        "3. List of rooms with the total amount of earned money, sorted in descending order"
    )
    print("4. Customers who booked more than one room in total")
    print("5. List of all available hours in each room for a specific day")
    print("6. Query and save to JSON")
    print("7. Update JSON data")
    print("8. One table")
    print("9. Many table")
    print("10. Insert data")
    print("11. Update data")
    print("12. Delete data")
    print("13. Execute stored procedure")

    choice = input("Enter the number of the menu item: ")

    if choice == "1":
        query_1()
    elif choice == "2":
        query_2()
    elif choice == "3":
        query_3()
    elif choice == "4":
        query_4()
    elif choice == "5":
        query_5()
    elif choice == "6":
        query_and_save_to_json()
    elif choice == "7":
        update_json_data(
            "rooms_data.json", {"name": "Room 1", "address": "New Address"}
        )
    elif choice == "8":
        one_table()
    elif choice == "9":
        many_table()
    elif choice == "10":
        insert_data()
    elif choice == "11":
        update_data()
    elif choice == "12":
        delete_data()
    elif choice == "13":
        execute_stored_procedure()

    # Закрытие сессии
    session.close()


if __name__ == "__main__":
    main()
