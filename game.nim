import std/strformat
import std/strutils
import std/tables
import std/files
import std/paths
import std/math
import parsetoml
# nico specifics
import nico
# OL imports
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
    tileset* : string                         # tileset name
    defs*    : OrderedTable[int, TilePrefab]  # tile definitions | index, TilePrefab object | meant to be static reference/preset without edits
    mapping* : OrderedTable[(int, int), Tile] # tile mapping     | (coords), Tile           | meant to be mutable (data can change)
    size*    : (int, int)                     # size             | (width, length)
  Map* = object
    data*     : MapData
    move*     : (int, int) # cell move from (0,0)
    kingdoms* : OrderedTable[int, Kingdom] # kingdoms used in game, searchable by index (should start from 1 upwards)
  Session* = object # game object, to store session data
    focus* : (int, int) # coordinates of tile that is currently highlighed | (-1, -1) are default (no tile)
    mode*  : MapMode

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

proc parseOLDATA (oldata_file: string): OrderedTable[int, TilePrefab] =
    # parses .oldata file and returns tile definitions in an OrderedTable
    let oldata = parseFile(fmt"tilesets/{oldata_file}")
    for tile_key in oldata.getTable.keys():
        if tile_key == "properties": discard # TODO | temporary

        result[parseInt(tile_key)] = newTilePrefab( # initialises prefab, using default values if key not found
                                                   tname   = oldata[tile_key]["name"].getStr(""),
                                                   road_ac = (false, false, false, false)         # TODO | temporary
                                                   )

proc parseOLM (olm_file: string): MapData =
    # - olm_file  : .olm file containing tileset and tile data
    let olm = parseFile(fmt"maps/{olm_file}")
    # check keys before we proceed
    for k in ["tileset_img", "tileset_data", "map"]:
        if olm.hasKey(k) == false: raise newException(Exception, fmt"Map file doesn't have all required keys! Key missing: {k}")

    result.tileset = olm["tileset_img"].getStr()
    var defs_path  = olm["tileset_data"].getStr()
    # before files are used, we ensure they exist
    for f in [result.tileset, defs_path]:
        if not fileExists(Path(fmt"tilesets/{f}")): raise newException(Exception, fmt"Map file directs to missing file: {f}")
    result.defs    = parseOLDATA(defs_path)
    # tile mapping
    for y, row in olm["map"].getElems().pairs:
        for x, ix in row.getElems().pairs:
            # ix = tile index; x/y = coordinates
            result.mapping[(x, y)] = newTile(result.defs, ix.getInt())
            if result.size[1] == 0: # sets itself only once
                result.size[0] += 1
        result.size[1] += 1

proc newMap* (olm_file: string, kingdoms: OrderedTable[int, Kingdom]): Map =
    # - olm_file  : .olm file containing tileset and tile data
    # - map_index : int | index 0 is for GUI/menu
    result.data     = parseOLM(olm_file)
    result.move     = (0, 0)
    result.kingdoms = kingdoms
    if len(result.data.mapping) < MV*MV: # temporary measure, we will eventually need to just center the map and adjust it to size in -drawMap-
        raise newException(Exception, fmt"Map file has too little tiles!")

proc drawMap* (map: Map) =
    useSpritesheet(XMap)
    for row in 0..<MV:      # 30 x 30 map area, adjusted to moved map
        for tile in 0..<MV:                   # adjusted to moved map
            let moved_coords = (tile + map.move[0], row + map.move[1])
            spr(map.data.mapping[moved_coords].index, tile * TL, row * TL)
            if map.data.mapping[moved_coords].road > 0:
                discard # here would be another `spr` that draws road on top, using also .roadcnn to determine tile

proc moveMap* (map: var Map, shift: (int, int), dt: float32) =
    # moves the starting coordinates if the boundaries are not outside 0..map_size range
    if map.move[0] + MV + shift[0] <= map.data.size[0] and
       map.move[1] + MV + shift[1] <= map.data.size[1] and
       map.move[0] + shift[0] >= 0 and
       map.move[1] + shift[1] >= 0:
        map.move[0] += shift[0]
        map.move[1] += shift[1]

proc highlightTile* (map: Map, tcoord: (int, int)) =
    rect(x1 = TL * (tcoord[0]-map.move[0])  , y1 = TL * (tcoord[1]-map.move[1]),
         x2 = TL * (tcoord[0]+1-map.move[0]), y2 = TL * (tcoord[1]+1-map.move[1]))

proc newSession* (): Session =
    result.focus = (-1, -1)
    result.mode  = EXPLORE