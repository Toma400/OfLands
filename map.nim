import std/strutils
import std/options
import std/tables
import questionable
# OL imports
import core/settlement
import core/entity
import kingdom

export EntityRole # exports so `addEntity` works from elsewhere

type
  TileBase* = enum # used for location building conditions (see proc `canExist`) and traversability (in the future/connected with roads)
    LAND
    WATER
    LAVA
    VOID
  TilePrefab* = object # it's the same as Tile, but meant to be static (not have data edited) | index is kept out so duplicates are replaced
    name   : string
    tbase  : TileBase
    mov_ct : int      # movement cost (base modifier)
  #  road_ac : RoadAccess # road accessibility (left, top, right, bottom)
  Tile* = object
    index*    : int          # terrain tile index
    name*     : string
    coords*   : tuple[x, y: int]
    tbase*    : TileBase
    mov_ct*   : int          # movement cost (base modifier) | -1 means unpassable // todo: is modified by roads (make proc for it)
    location* : ?Location
    settile*  : ?SettlementTile
    entities  : seq[Entity]  # private so it can't be accessed without proper handling (adding both to Tile and Kingdom)
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
    result.name   = ""
    result.tbase  = VOID
    result.mov_ct = 0
    # result.road_ac = (true, true, true, true)

proc newTilePrefab* (tbase: string, mv_cost: int, tname: string = ""): TilePrefab = #, road_ac: RoadAccess): TilePrefab =
    result.name   = tname
    result.tbase  = getTileBase(tbase)
    result.mov_ct = mv_cost
    # result.road_ac = road_ac

proc newTile* (tp: TilePrefab, ix: int, coords: tuple[x, y: int]): Tile = #, road: int): Tile =
    # converter to allow for tile to have dynamic data under exported struct
    result.index    = ix
    result.name     = tp.name
    result.coords   = coords
    result.tbase    = tp.tbase
    result.mov_ct   = tp.mov_ct
    result.location = Location.none       # set later
    result.settile  = SettlementTile.none # set later
    result.entities = newSeq[Entity]() # empty, use `addEntity()` proc to fill
    #result.road_ac = tp.road_ac
    #result.road    = road       # 0 = no road; 1 = dirt road; 2 = rock road

proc newTile* (oldata: OrderedTable[int, TilePrefab], ix: int, coords: tuple[x, y: int]): Tile =
    # converted that yields singular tile data from TilePrefab table
    if ix in oldata:
        return newTile(oldata[ix], ix, coords)#, 0) # todo: 0 is temporary
    return newTile(defaultTilePrefab(), ix, coords)#, 0) # as above

proc hasObject* (t: Tile): bool =
    # checks whether tile is occupied by location or settlement
    return isSome(t.location) or isSome(t.settile)

proc canExist* (t: Tile, l: Location): bool =
    # proc to see if tile can have location built (it is *not* about traversability)
    if t.tbase == TileBase.VOID:                                        return false # void can't have any location existing
    # non-void cases
    case l.bcond:
      of BuildingConditions.LAND:
          if t.tbase == TileBase.LAND:                                  return true
      of BuildingConditions.WATER:
          if t.tbase == TileBase.WATER:                                 return true
      of BuildingConditions.SUBMERGED:
          if t.tbase in [TileBase.LAND, TileBase.WATER]:                return true
      of BuildingConditions.AIR:
          if t.tbase in [TileBase.LAND, TileBase.WATER, TileBase.LAVA]: return true
      of BuildingConditions.ALL:                                        return true
      of BuildingConditions.NONE:                                       return false
    return false # if any catches earlier for true are not met

proc canSettlementExist* (t: Tile): bool =
    # for settlements
    if t.tbase == LAND: return true
    return false

proc canStand* (t: Tile, er: EntityRole): bool =
    # checks whether the entity can exist on particular tile (it is *not* about traversability)
    case t.tbase:
        of TileBase.VOID: return false # is not traversed by anything
        of TileBase.LAND:
            return er in LAND_ENTITY
        of TileBase.WATER:
            return er in WATER_ENTITY
        of TileBase.LAVA: return false
            #if er in []: return true | todo: uncheck when there's air/lava entities
    return false # if any catches earlier for true are not met

proc addEntity* (t: var Tile, k: var Kingdom, er: EntityRole): bool =
    # also works as a constructor; return false if entity can't be made
    if canStand(t, er):
        var e = newEntity(er, k.number)
        t.entities.add(e)
        k.entities.add(e)
        return true
    return false

proc addLocation* (t: var Tile, k: var Kingdom, l: Location): bool =
    discard

proc addSettlement* (t: var Tile, k: var Kingdom): bool =
    if not hasObject(t) and canSettlementExist(t): # checks if tile is occupied + if settlement can be put
        let stt = newSettlementTile(t.coords)
        let stm = newSettlement(generateRandomName(), @[stt], k.number)
        t.settile = stt.some # binds SettlementTile to Tile
        k.settlems.add(stm)  # binds Settlement to Kingdom
        return true
    return false

proc getEntityList* (t: Tile): seq[Entity] = # todo: ensure you can't add to t.entities, so that seq is read-only (and/or you can only edit its Entity refs)
    return t.entities

# proc canBuildRoad* (t: Tile | TilePrefab): bool =
#     # check if any of RoadAccess sides are available (none = not possible to build road)
#     any(t.road_ac, proc (s: bool): bool = s == true)