import datetime
import typing
from dataclasses import dataclass


@dataclass
class Customer:
    customer_id: int
    name: str
    phone_number: str
    email: str
    ban: bool


@dataclass
class Room:
    room_id: int
    name: str
    address: str
    price_per_hour: int
    min_hours: int


@dataclass
class Hour:
    hour_id: int
    room_id: int
    rehearsal_id: typing.Optional[int]
    date: datetime.date
    hour: int


@dataclass
class Rehearsal:
    rehearsal_id: int
    customer_id: int
    date: datetime.date
    customer_rate: int
    room_rate: int
    additional_info: str


@dataclass
class RehearsalHour:
    id: int
    rehearsal_id: int
    hour_id: int


@dataclass
class RehearsalRoom:
    id: int
    rehearsal_id: int
    room_id: int
    status: int
