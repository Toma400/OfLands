import std/tables
import std/math
import ../game

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
const MonthDayCap = {
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
    proc remainingTime(base, divident: int): int =
        # used as smart `divmod` to avoid 0s
        result = divmod(base, divident)[1]
        if result < 1: return 1 # protects from 0/negative numbers

    # ses.tick += 1       | remnants of non-turn-based system - just uncomment them (`turn` block is used as condition equivalent)
    #if ses.tick mod 40:
    block turn:
        map.time.hour += progress_hours
        if map.time.hour > 24:
            map.time.day += floorDiv(map.time.hour, 24)
            map.time.hour = remainingTime(map.time.hour, 24)
        if map.time.day > MonthDayCap[map.time.month]:
            let cap = MonthDayCap[map.time.month] # separated so it isn't affected by first change
            map.time.month += floorDiv(map.time.day, cap)
            map.time.day    = remainingTime(map.time.day, cap)
        if map.time.month > 12:
            map.time.year += floorDiv(map.time.month, 12)
            map.time.month = remainingTime(map.time.month, 12)
        # ses.tick = 1 # resets