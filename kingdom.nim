import std/strutils
import std/tables
import core/settlement
import core/entity

type
  BuildingConditions* = enum
    LAND
    WATER
    SUBMERGED # used for water + land combination
    AIR
    ALL
    NONE      # should not be used in .oldata, indicates wrong entry
  Kingdom* = object
    name*      : string
    number*    : int
    locations* : seq[(int, int)] # coordinates to `MapData.mapping` Tile
    entities*  : seq[Entity]
    settlems*  : seq[Settlement]
  LocationPrefab* = object # immutable variant used before instance is made
    name*  : string
    bcond* : BuildingConditions
  Location* = object
    index* : int               # location tile index
    name*  : string
    bcond* : BuildingConditions
    owner* : int               # 0 for unowned, otherwise takes kingdom index (1-n) used by the Map object
    # todo: settlement ownership?
    walls* : int               # 0 for no walls, 1 for pallisade, 2 for stone wall | todo: .oldata should be able to overwrite this
    # todo: storage for resources

proc `$`* (k: Kingdom): string =
    return k.name

proc `$`* (l: Location): string =
    return $l.index

proc getBuildingCondition* (id: string): BuildingConditions =
    case id.toLowerAscii():
      of "land":      return LAND
      of "water":     return WATER
      of "submerged": return SUBMERGED
      of "air":       return AIR
      of "all":       return ALL
      else:           return NONE

proc newKingdom* (name: string, number: int): Kingdom =
    result.name      = name
    result.number    = number
    result.locations = newSeq[(int, int)]()

proc defaultLocationPrefab* (): LocationPrefab =
    # default values; used when there's no data available | bcond NONE should remove it from game during map parse
    result.name  = ""
    result.bcond = BuildingConditions.NONE

proc newLocationPrefab* (bcond: string, lname: string = ""): LocationPrefab =
    result.name  = lname
    result.bcond = getBuildingCondition(bcond)

proc newLocation* (lp: LocationPrefab, ix: int, owner: int = 0, walls: int = 0): Location =
    # use -newLocation- found in game.nim, this is only helper for it! (should be merged when new directory system is made)
    # ....actually it's not a helper rn, but it's needed for .olm parser as one allowing for no `map` argument to exist
    result.index = ix
    result.name  = lp.name
    result.bcond = lp.bcond
    result.owner = owner
    result.walls = walls

proc newLocation* (oldata: OrderedTable[int, LocationPrefab], ix: int): Location =
    # converted that yields singular loc data from LocationPrefab table
    if ix in oldata:
        return newLocation(oldata[ix], ix) # todo: may be good to fill `owner` and `walls`?
    return newLocation(defaultLocationPrefab(), ix) # todo?

proc initKingdoms* (ks: varargs[Kingdom]): OrderedTable[int, Kingdom] =
    for k in ks:
        if k.number < 1:
            raise newException(Exception, "Kingdom number must be positive.")
        result[k.number] = k