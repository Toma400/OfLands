import std/tables

type
  RoadAccess = tuple[left: bool, up: bool, right: bool, down: bool]
  #[ RoadAccess | indicates connections possible from the tile - no connection means the tile is isolated and thus doesn't support road building
                | notes: rivers wouldn't support roads at all - bridge would be separate structure (location) that enables that
                |        e.g. river going horizontally would create bridge looking like that: ||
                |             meaning the directions opening are up and down
                |        not unlikely we would want bridges with each connection fulfilled though (e.g. bridge w/o roads, bridge with up, bridge
                |                                                                                       with down and both directions)
  ]#
  TilePrefab* = object # it's the same as Tile, but meant to be static (not have data edited) | index is kept out so duplicates are replaced
    name    : string
    road_ac : RoadAccess # road accessibility (left, top, right, bottom)
  Tile* = object
    index*    : int        # terrain tile index
    name*     : string
    road_ac*  : RoadAccess # road accessibility (left, top, right, bottom)
    road*     : int        # whether tile has road (0 - none, 1 - dirt, 2 - rock)
    road_cnn* : RoadAccess # whether nearby tiles (left, top, right, bottom) have road to connect to
    #[ 'singleton' fields
    road     | not-bool because type can be used // also road connections (that gets updated when new road is made, but set up during initial tile creation*)
             | * or actually after, because initially you won't get all tiles - probably there should be second round through `mapping` that checks for all
             |   nearby tiles and sets up connections, picking up sprite that has the same flags
             | [tile setup however could recognise if terrain allows for road, which would be good .oldata entry]
    entity   |
    location |]#

proc defaultTilePrefab* (): TilePrefab =
    # default values; used when there's no data available
    result.name    = ""
    result.road_ac = (true, true, true, true)

proc newTilePrefab* (tname: string = "", road_ac: RoadAccess): TilePrefab =
    result.name    = tname
    result.road_ac = road_ac

proc newTile* (tp: TilePrefab, ix: int, road: int): Tile =
    # converter to allow for tile to have dynamic data under exported struct
    result.index   = ix
    result.name    = tp.name
    result.road_ac = tp.road_ac
    result.road    = road       # 0 = no road; 1 = dirt road; 2 = rock road

proc newTile* (oldata: OrderedTable[int, TilePrefab], ix: int): Tile =
    # converted that yields singular tile data from TilePrefab table
    if ix in oldata:
        return newTile(oldata[ix], ix, 0) # todo: 0 is temporary
    return newTile(defaultTilePrefab(), ix, 0) # as above

proc canBuildRoad* (t: Tile | TilePrefab): bool =
    # check if any of RoadAccess sides are available (none = not possible to build road)
    any(t.road_ac, proc (s: bool): bool = s == true)