import std/strformat
import std/strutils
import std/tables
import std/files
import std/paths
import std/math
import parsetoml
import questionable
# nico specifics
import nico
# OL imports
import core/entity
import kingdom
import render
import map

const TL* = 32 # tile width/length
const MV* = 30 # map view size (default = 30)

type
  MapMode* = enum # modes used by session to filter through actions (e.g. for I/O to not focus on tile if you are now doing building)
    EXPLORE         # default mode  | clicking on tile focuses on it and allow management if tile belongs to you)
    ROUTE           # route mode    | clicking adds route node
    TRAVEL          # travel mode   | clicking directs entity to particular cell
    TRADE           # trade mode    | clicking sets destination for trade
    BUILDING        # building mode | clicking adds a construction plan
  MapData* = object
    tterrain* : string                            # terrain tileset name
    tlocs*    : string                            # location tileset name
    tsys*     : string                            # system tileset name
    tdefs*    : OrderedTable[int, TilePrefab]     # tile definitions | index, TilePrefab object     | meant to be static reference/preset without edits
    ldefs*    : OrderedTable[int, LocationPrefab] # loc definitions  | index, LocationPrefab object | meant to be static reference/present without edits
    mapping*  : OrderedTable[(int, int), Tile]    # tile mapping     | (coords), Tile               | meant to be mutable (data can change)
    size*     : (int, int)                        # size             | (width, length)
  Map* = object
    data*     : MapData
    move*     : (int, int)                         # cell move from (0,0)
    kingdoms* : OrderedTable[int, Kingdom]         # kingdoms used in game, searchable by index (should start from 1 upwards)
    time*     : tuple[year, month, day, hour: int]
  Session* = object # game object, to store session data
    focus* : (int, int) # coordinates of tile that is currently highlighed | (-1, -1) are default (no tile)
    mode*  : MapMode
    tick*  : int        # serves as a counter of each frame (used for some events)

proc isPxWithinMap* (map: Map, px_coord: (int, int)): bool =
    # does not calculate move - only if particular pixel is within 30x30 bonds (calculate moved px when calling)
    if px_coord[0] > MV*TL or
       px_coord[1] > MV*TL:
        return false
    return true

proc isTileWithinMap* (map: Map, t_coord: (int, int)): bool =
    return isPxWithinMap(map, ((t_coord[0]-map.move[0])*TL,    (t_coord[1]-map.move[1])*TL)) and
           isPxWithinMap(map, ((t_coord[0]-map.move[0])*TL+TL, (t_coord[1]-map.move[1])*TL+TL))

proc getCellCoords* (map: Map, px_coord: (int, int)): (int, int) =
    # yields coordinates of cell from pixel coordinates (adjusting to map move)
    if not isPxWithinMap(map, px_coord):
        return (-1, -1) # outside of cell window
    return (floor(px_coord[0]/TL).int + map.move[0],
            floor(px_coord[1]/TL).int + map.move[1])

proc parseTerrainOLDATA (oldata_file: string): OrderedTable[int, TilePrefab] =
    # parses .oldata file and returns tile definitions in an OrderedTable
    let oldata = parseFile(fmt"tilesets/{oldata_file}")
    for cat in oldata.getTable.keys():
        if cat == "tile":
            for tile_key in oldata["tile"].getTable.keys():
                result[parseInt(tile_key)] = newTilePrefab( # initialises prefab, using default values if key not found
                                                           tname = oldata["tile"][tile_key]["name"].getStr(""),
                                                           tbase = oldata["tile"][tile_key]["tbase"].getStr(""),
                                                           #road_ac = (false, false, false, false)         # TODO | temporary
                                                           )

proc parseLocationOLDATA (oldata_file: string): OrderedTable[int, LocationPrefab] =
    # parses .oldata file and returns tile definitions in an OrderedTable
    let oldata = parseFile(fmt"tilesets/{oldata_file}")
    for cat in oldata.getTable.keys():
        if cat == "tile":
            for tile_key in oldata["tile"].getTable.keys():
                result[parseInt(tile_key)] = newLocationPrefab( # initialises prefab, using default values if key not found
                                                               lname = oldata["tile"][tile_key]["name"].getStr(""),
                                                               bcond = oldata["tile"][tile_key]["bcond"].getStr(""),
                                                               )

proc parseOLM (olm_file: string): MapData =
    # - olm_file  : .olm file containing tileset and tile data
    let olm = parseFile(fmt"maps/{olm_file}")
    # check keys before we proceed
    for k in ["tileset_terrain", "tileset_locations", "tileset_system", "data_terrain", "data_locations", "terrain"]:
        if olm.hasKey(k) == false: raise newException(Exception, fmt"Map file doesn't have all required keys! Key missing: {k}")

    result.tterrain = olm["tileset_terrain"].getStr()
    result.tlocs    = olm["tileset_locations"].getStr()
    result.tsys     = olm["tileset_system"].getStr()
    var tdefs_path  = olm["data_terrain"].getStr()
    var ldefs_path  = olm["data_locations"].getStr()
    # before files are used, we ensure they exist
    for f in [result.tterrain, result.tlocs, result.tsys, tdefs_path, ldefs_path]:
        if not fileExists(Path(fmt"tilesets/{f}")): raise newException(Exception, fmt"Map file directs to missing file: {f}")
    result.tdefs = parseTerrainOLDATA(tdefs_path)
    result.ldefs = parseLocationOLDATA(ldefs_path)
    # tile mapping
    for y, row in olm["terrain"].getElems().pairs:
        for x, ix in row.getElems().pairs:
            # ix = tile index; x/y = coordinates
            result.mapping[(x, y)] = newTile(result.tdefs, ix.getInt())
            if result.size[1] == 0: # sets itself only once
                result.size[0] += 1
        result.size[1] += 1
    # tile mapping (locations)
    for y, row in olm["locations"].getElems().pairs:
        for x, ix in row.getElems().pairs:
            # ix = tile index; x/y = coordinates
            if ix.getInt() != -1: # no location
                result.mapping[(x, y)].location = newLocation(result.ldefs, ix.getInt()).some # todo: rest is using default 0, because this is probably how it should be?
                                                                                # try to find out how to potentially edit this? but unaffiliation makes sense
                if not canExist(result.mapping[(x, y)], !result.mapping[(x, y)].location): # if conditions are not met, location is axed to default
                    result.mapping[(x, y)].location = Location.none
                # also todo: make Tile have 'waterTile/landTile' that determines location placement, and location be `type` that determines
                #            if placement is valid for particular type (e.g. `waterType` would only go to `waterTile` etc.)

proc newMap* (olm_file: string, kingdoms: OrderedTable[int, Kingdom], starting_date: (int, int, int)): Map =
    # - olm_file  : .olm file containing tileset and tile data
    # - map_index : int | index 0 is for GUI/menu
    result.data     = parseOLM(olm_file)
    result.move     = (0, 0)
    result.kingdoms = kingdoms
    result.time     = (year: starting_date[0], month: starting_date[1], day: starting_date[2], hour: 1)
    if result.time.year < 1 or result.time.month < 1 or result.time.day < 1:
        raise newException(Exception, fmt"Game has incorrect date set. Date needs every value (year/month/day) be positive number!")
    if len(result.data.mapping) < MV*MV: # temporary measure, we will eventually need to just center the map and adjust it to size in -drawMap-
        raise newException(Exception, fmt"Map file has too little tiles!")

proc drawMap* (map: Map) =
    for row in 0..<MV:      # 30 x 30 map area, adjusted to moved map
        for tile in 0..<MV:                   # adjusted to moved map
            let moved_coords = (tile + map.move[0], row + map.move[1])
            let tile_drawn   = map.data.mapping[moved_coords]
            useSpritesheet(XMap)
            spr(tile_drawn.index, tile * TL, row * TL)
            if tile_drawn.location.isSome:
                useSpritesheet(XLoc)
                spr((!tile_drawn.location).index, tile * TL, row * TL)
            let entity_count = getEntityList(tile_drawn).len
            if entity_count > 0:
                useSpritesheet(XSys)
                spr(getEntityList(tile_drawn)[entity_count-1].role.ord, tile * TL, row * TL) # uses last entity that moved onto tile
            # if map.data.mapping[moved_coords].road > 0:
            #     discard # here would be another `spr` that draws road on top, using also .roadcnn to determine tile

proc moveMap* (map: var Map, shift: (int, int), dt: float32) =
    # moves the starting coordinates if the boundaries are not outside 0..map_size range
    if map.move[0] + MV + shift[0] <= map.data.size[0] and
       map.move[1] + MV + shift[1] <= map.data.size[1] and
       map.move[0] + shift[0] >= 0 and
       map.move[1] + shift[1] >= 0:
        map.move[0] += shift[0]
        map.move[1] += shift[1]

# proc newLocation* (map: var Map, affiliation: int = 0) =
#     # creates location and puts it on particular tile # todo? make variant without `map` needed that is by auto unaffiliated?
#     # what is this even used with?? no usages found tbh
#     let loc = newLocation(affiliation)
#     if affiliation != 0:
#         map.kingdoms[affiliation].locations.add(loc)

proc highlightTile* (map: Map, tcoord: (int, int)) =
    rect(x1 = TL * (tcoord[0]-map.move[0])  , y1 = TL * (tcoord[1]-map.move[1]),
         x2 = TL * (tcoord[0]+1-map.move[0]), y2 = TL * (tcoord[1]+1-map.move[1]))

proc newSession* (): Session =
    result.focus = (-1, -1)
    result.mode  = EXPLORE
    result.tick  = 1