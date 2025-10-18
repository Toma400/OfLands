import std/strutils
import std/options
import std/tables
import questionable
# OL imports
import kingdom

type
  TileBase* = enum # used for location building conditions (see proc `canExist`) and traversability (in the future/connected with roads)
    LAND
    WATER
    LAVA
    VOID
  TilePrefab* = object # it's the same as Tile, but meant to be static (not have data edited) | index is kept out so duplicates are replaced
    name  : string
    tbase : TileBase
  #  road_ac : RoadAccess # road accessibility (left, top, right, bottom)
  Tile* = object
    index*    : int        # terrain tile index
    name*     : string
    tbase*    : TileBase
    location* : ?Location
    # road_ac*  : RoadAccess # road accessibility (left, top, right, bottom)
    # road*     : int        # whether tile has road (0 - none, 1 - dirt, 2 - rock)
    # road_cnn* : RoadAccess # whether nearby tiles (left, top, right, bottom) have road to connect to
    #[ 'singleton' fields
    road     | not-bool because type can be used // also road connections (that gets updated when new road is made, but set up during initial tile creation*)
             | * or actually after, because initially you won't get all tiles - probably there should be second round through `mapping` that checks for all
             |   nearby tiles and sets up connections, picking up sprite that has the same flags
             | [tile setup however could recognise if terrain allows for road, which would be good .oldata entry]
    entity   |
    location |]#

proc getTileBase* (id: string): TileBase =
    case id.toLowerAscii():
      of "land":  return LAND
      of "water": return WATER
      of "lava":  return LAVA
      else:       return VOID

proc defaultTilePrefab* (): TilePrefab =
    # default values; used when there's no data available
    result.name  = ""
    result.tbase = VOID
    # result.road_ac = (true, true, true, true)

proc newTilePrefab* (tbase: string, tname: string = ""): TilePrefab = #, road_ac: RoadAccess): TilePrefab =
    result.name  = tname
    result.tbase = getTileBase(tbase)
    # result.road_ac = road_ac

proc newTile* (tp: TilePrefab, ix: int): Tile = #, road: int): Tile =
    # converter to allow for tile to have dynamic data under exported struct
    result.index    = ix
    result.name     = tp.name
    result.tbase    = tp.tbase
    result.location = Location.none # set later
    #result.road_ac = tp.road_ac
    #result.road    = road       # 0 = no road; 1 = dirt road; 2 = rock road

proc newTile* (oldata: OrderedTable[int, TilePrefab], ix: int): Tile =
    # converted that yields singular tile data from TilePrefab table
    if ix in oldata:
        return newTile(oldata[ix], ix)#, 0) # todo: 0 is temporary
    return newTile(defaultTilePrefab(), ix)#, 0) # as above

proc canExist* (t: Tile, l: Location): bool =
    # proc to see if tile can have location built (it is *not* about traversability)
    if t.tbase == TileBase.VOID:                                        return false # void can't have any location existing
    # non-void cases
    case l.bcond:
      of BuildingConditions.LAND:
          if t.tbase == TileBase.LAND:                                  return true
      of BuildingConditions.WATER:
          if t.tbase == TileBase.WATER:                                 return true
      of BuildingConditions.AIR:
          if t.tbase in [TileBase.LAND, TileBase.WATER, TileBase.LAVA]: return true
      of BuildingConditions.ALL:                                        return true
      of BuildingConditions.NONE:                                       return false
    return false # if any catches earlier for true are not met

# proc canBuildRoad* (t: Tile | TilePrefab): bool =
#     # check if any of RoadAccess sides are available (none = not possible to build road)
#     any(t.road_ac, proc (s: bool): bool = s == true)