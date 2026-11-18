import std/strutils
import std/tables
import core/settlement
import core/location
import core/entity

type
  Kingdom* = object
    name*      : string
    number*    : int
    locations* : seq[tuple[x, y: int]] # coordinates to `MapData.mapping` Tile
    entities*  : seq[Entity]
    settlems*  : seq[Settlement]
    start*     : tuple[x, y: int]      # initial coordinates kingdom starts in
    descr*     : string                # description

proc `$`* (k: Kingdom): string =
    return k.name

proc newKingdom* (name: string, number: int, start: tuple[x, y: int] = (0, 0), descr: string = ""): Kingdom =
    result.name      = name
    result.number    = number
    result.locations = newSeq[(int, int)]()
    result.start     = start
    result.descr     = descr