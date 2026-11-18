import std/strformat
import std/strutils
import std/tables
import std/random
import resources
import logging
randomize()

type
  BuildingConditions* = enum
    LAND
    WATER
    SUBMERGED # used for water + land combination
    AIR
    ALL
    NONE      # should not be used in .oldata, indicates wrong entry
  LocationPrefab* = ref object # immutable variant used before instance is made
    name*     : string
    bcond*    : BuildingConditions
    res_cap*  : int                    # resources' weight cap
    res_pool* : OrderedTable[int, tuple[low, high: int]] # unowned pool
  Location* = ref object
    index*   : int                     # location tile index
    name*    : string
    bcond*   : BuildingConditions
    res*     : OrderedTable[int, int]  # resources stored (resource ID, amount)
    res_cap* : int                     # resources' weight cap
    res_wgt* : int                     # resources' weight (for easy access, overridden when res added/removed)
    owner*   : int                     # 0 for unowned, otherwise takes kingdom index (1-n) used by the Map object
    # todo: settlement ownership?
    walls*   : int                     # 0 for no walls, 1 for pallisade, 2 for stone wall | todo: .oldata should be able to overwrite this

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

proc defaultLocationPrefab* (): LocationPrefab =
    # default values; used when there's no data available | bcond NONE should remove it from game during map parse
    new(result)
    result.name    = ""
    result.bcond   = BuildingConditions.NONE
    result.res_cap = 0

proc newLocationPrefab* (bcond: string, lname: string = "", res_cap: int, loot: OrderedTable[int, tuple[low, high: int]]): LocationPrefab =
    new(result)
    result.name     = lname
    result.bcond    = getBuildingCondition(bcond)
    result.res_cap  = res_cap
    result.res_pool = loot

proc newLocation* (lp: LocationPrefab, ix: int, owner: int = 0, walls: int = 0): Location =
    # use -addLocation- found in game.nim/map.nim, this is only helper for it! (should be merged when new directory system is made)
    # ....actually it's not a helper rn, but it's needed for .olm parser as one allowing for no `map` argument to exist
    new(result)
    result.index   = ix
    result.name    = lp.name
    result.bcond   = lp.bcond
    result.res_cap = lp.res_cap
    result.res_wgt = 0
    result.owner   = owner
    result.walls   = walls
    # adding resources to unowned location requires `addLocation` in game.nim

proc newLocation* (oldata: OrderedTable[int, LocationPrefab], ix: int): Location =
    # converted that yields singular loc data from LocationPrefab table
    if ix in oldata:
        return newLocation(oldata[ix], ix) # todo: may be good to fill `owner` and `walls`?
    log |: fmt"Couldn't find location of ID: {ix}. Skipping placement."
    return newLocation(defaultLocationPrefab(), ix) # todo?