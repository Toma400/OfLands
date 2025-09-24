import std/tables

type
  Kingdom* = object
    name : string

proc `$`* (k: Kingdom): string =
    return k.name

proc newKingdom* (name: string): Kingdom =
    result.name = name

proc initKingdoms* (ks: varargs[Kingdom]): OrderedTable[int, Kingdom] =
    var counter = 1 # index 0 is reserved for emptied locations
    for k in ks:
        result[counter] = k
        counter += 1