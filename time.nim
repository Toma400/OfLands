import std/tables
import game

const Month* = {
    1:  "January",
    2:  "February",
    3:  "March",
    4:  "April",
    5:  "May",
    6:  "June",
    7:  "July",
    8:  "August",
    9:  "September",
    10: "October",
    11: "November",
    12: "December"
}.toTable
const MonthDayCap* = {
    1:  31,
    2:  28,
    3:  31,
    4:  30,
    5:  31,
    6:  30,
    7:  31,
    8:  31,
    9:  30,
    10: 31,
    11: 30,
    12: 31
}.toTable

proc passTime* (map: var Map, ses: var Session, progress_hours: int = 1) =
    ses.tick += 1
    if ses.tick mod 40 == 0:
        map.time.hour += progress_hours
        if map.time.hour > 24:
            map.time.day += 1
            map.time.hour = 1
        if map.time.day > MonthDayCap[map.time.month]:
            map.time.month += 1
            map.time.day    = 1
        if map.time.month > 12:
            map.time.year += 1
            map.time.month = 1
        ses.tick = 1 # resets