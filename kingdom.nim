import std/tables

type
  Kingdom* = object
    name*      : string
    number*    : int
    locations* : seq[Location] # uint8 is temporary
  Location* = object
    owner* : int               # 0 for unowned, otherwise takes kingdom index (1-n) used by the Map object
    # todo: settlement ownership?
    walls* : int               # 0 for no walls, 1 for pallisade, 2 for stone wall | todo: .oldata should be able to overwrite this
    # todo: storage for resources

proc `$`* (k: Kingdom): string =
    return k.name

proc newKingdom* (name: string, number: int): Kingdom =
    result.name      = name
    result.number    = number
    result.locations = newSeq[Location]()

proc newLocation* (owner: int = 0, walls: int = 0): Location =
    # use -newLocation- found in game.nim, this is only helper for it! (should be merged when new directory system is made)
    result.owner = owner
    result.walls = walls

proc initKingdoms* (ks: varargs[Kingdom]): OrderedTable[int, Kingdom] =
    for k in ks:
        if k.number < 1:
            raise newException(Exception, "Kingdom number must be positive.")
        result[k.number] = k