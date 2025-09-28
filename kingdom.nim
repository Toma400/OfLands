import std/tables

type
  Kingdom* = object
    name*      : string
    number*    : int
    locations* : seq[Location] # uint8 is temporary
  Location* = object
    owner* : int               # 0 for unowned, otherwise takes kingdom index (1-n) used by the Map object

proc `$`* (k: Kingdom): string =
    return k.name

proc newKingdom* (name: string, number: int): Kingdom =
    result.name      = name
    result.number    = number
    result.locations = newSeq[Location]()

proc initKingdoms* (ks: varargs[Kingdom]): OrderedTable[int, Kingdom] =
    for k in ks:
        if k.number < 1:
            raise newException(Exception, "Kingdom number must be positive.")
        result[k.number] = k