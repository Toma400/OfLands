#################################################
# ROADS
# Module for handling road system
#################################################
import std/threadpool
import std/tables
import std/times
import ../game
import ../map

# type
# RoadAccess = tuple[...]
#   #[ RoadAccess | indicates connections possible from the tile - no connection means the tile is isolated and thus doesn't support road building
#                 | notes: rivers wouldn't support roads at all - bridge would be separate structure (location) that enables that
#                 |        e.g. river going horizontally would create bridge looking like that: ||
#                 |             meaning the directions opening are up and down
#                 |        not unlikely we would want bridges with each connection fulfilled though (e.g. bridge w/o roads, bridge with up, bridge
#                 |                                                                                       with down and both directions)
#   ]#

const ROAD_INIT = {
    # initial indexes for road tiles (+n for specific variant)
    1: 13, # dirt
    2: 26  # stone
}.toTable

proc sum (c: Routes): int =
    for i in c.fields():
        result += i

proc roadOrdering (road: int, neighbours: Routes): seq[int] =
    # road = int value (needs check for `road` to not be 0); blitting should check upon `road` value, not `routes` nor `roaddraw`
    if sum(neighbours) == 0: return @[ROAD_INIT[road] + 12] # if alone, just center
    let road_init = ROAD_INIT[road]
    let diagonals = neighbours.RU + neighbours.RD + neighbours.LD + neighbours.LU > 0
    # if diagonals exist, start with "long diagonals"
    if diagonals:
        if neighbours.RU > 0: result.add(road_init + 4)
        if neighbours.RD > 0: result.add(road_init + 5)
        if neighbours.LD > 0: result.add(road_init + 6)
        if neighbours.LU > 0: result.add(road_init + 7)
    # now, regular verticals/horizonstals
    if neighbours.R > 0: result.add(road_init)
    if neighbours.D > 0: result.add(road_init + 1)
    if neighbours.L > 0: result.add(road_init + 2)
    if neighbours.U > 0: result.add(road_init + 3)
    # shorter diagonals to
    if diagonals:
        if neighbours.RU > 0: result.add(road_init + 8)
        if neighbours.RD > 0: result.add(road_init + 9)
        if neighbours.LD > 0: result.add(road_init + 10)
        if neighbours.LU > 0: result.add(road_init + 11)

proc updateRoads* (map: ptr Map, coord: tuple[x, y: int], road_val: int) {.thread.} =
    proc roadValue (m: OrderedTable[tuple[x, y: int], Tile], c: tuple[x, y: int]): int = # should be done on mapping, not map
        if c in m: return m[c].road
        return 0 # if tile doesn't exist

    map.data.mapping[coord].road = road_val
    if road_val == 0:
        map.data.mapping[coord].roaddraw = newSeq[int]()
        return # early return, so no calculation is done later

    let
      x_left  = coord.x - 1
      x_right = coord.x + 1
      y_up    = coord.y - 1
      y_down  = coord.y + 1
      mapp    = map.data.mapping # only use for checks
    # update road reference to current tile (no need to do reversely, as that particular tile will update later anyway)
    # left column
    # if (x_right, coord.y) in mapp: map.data.mapping[(x_right, coord.y)].routes.L = road_val
    # if (x_right, y_up)    in mapp: map.data.mapping[(x_right, y_up)].routes.LD   = road_val
    # if (x_right, y_down)  in mapp: map.data.mapping[(x_right, y_down)].routes.LU = road_val
    # # right column
    # if (x_left, coord.y) in mapp: map.data.mapping[(x_left, coord.y)].routes.R   = road_val
    # if (x_left, y_up)    in mapp: map.data.mapping[(x_left, y_up)].routes.RD     = road_val
    # if (x_left, y_down)  in mapp: map.data.mapping[(x_left, y_down)].routes.RU   = road_val
    # # center
    # if (coord.x, y_up)   in mapp: map.data.mapping[(coord.x, y_up)].routes.D     = road_val
    # if (coord.x, y_down) in mapp: map.data.mapping[(coord.x, y_down)].routes.U   = road_val

    map.data.mapping[coord].roaddraw = roadOrdering(road_val, (L  : roadValue(mapp, (x_left,  coord.y)),
                                                               LU : roadValue(mapp, (x_left,  y_up)),
                                                               U  : roadValue(mapp, (coord.x, y_up)),
                                                               RU : roadValue(mapp, (x_right, y_up)),
                                                               R  : roadValue(mapp, (x_right, coord.y)),
                                                               RD : roadValue(mapp, (x_right, y_down)),
                                                               D  : roadValue(mapp, (coord.x, y_down)),
                                                               LD : roadValue(mapp, (x_left,  y_down))
    ))

# proc updateRoads* (map: ptr Map) =
#     # updates all roads across the map, setting up their routes and drawing ordering (should be done only initially)
#     var pool: seq[FlowVar[bool]] = @[]
#
#     #let size = map.data.size[0] * map.data.size[1]
#     #let init = cpuTime()
#     #var ix   = 0
#     #echo "ROAD UPDATING"
#     for coord, tile in map.data.mapping.pairs():
#         if pool.len <= 100:
#             pool.add(spawn updateRoads(map, coord, tile.road))
#         else: # over 100 pools
#             let needle = blockUntilAny(pool)
#             pool.del(needle)
#             pool.add(spawn updateRoads(map, coord, tile.road))
#         # echo coord
#         # echo tile.road
#         # updateRoads(map, coord, tile.road)
#         # ix += 1
#         # echo "UPDATED SUCCESSFULLY! TILES PROCESSED: " & $ix & " / " & $size
#     #echo "FINISHED ROAD UPDATING IN: " & $(cpuTime() - init)

proc updateRoads* (map: var Map) =
    #for coord, tile in map.data.mapping.pairs():
    for x in map.move[0]..map.move[0]+TL:
      for y in map.move[1]..map.move[1]+TL:
          if map.data.mapping[(x, y)].roadch == false:
              updateRoads(addr map, (x, y), map.data.mapping[(x, y)].road)
              map.data.mapping[(x, y)].roadch = true