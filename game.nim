import std/strformat
import std/strutils
import std/tables
import std/files
import std/paths
import std/math
import parsetoml
# nico specifics
import nico

const TL* = 32 # tile width/length

type
  MapMode* = enum # modes used by session to filter through actions (e.g. for I/O to not focus on tile if you are now doing building)
    EXPLORE         # default mode | clicking on tile focuses on it and allow management if tile belongs to you)
    ROUTE           # route mode   | clicking adds route node
    TRAVEL          # travel mode  | clicking directs entity to particular cell
    TRADE           # trade mode   | clicking sets destination for trade
  Indexes* = enum # spreadsheet indexes (to be later reconceptualised)
    XMap      = 1
    XFeatures = 2
    XGrid     = 3
  Tile* = object
    index* : int     # terrain tile index
    name*  : string
  MapData* = object
    tileset* : string                         # tileset name
    palette* : string                         # palette name
    defs*    : OrderedTable[int, Tile]        # tile definitions | index, Tile object | meant to be static reference/preset without edits
    mapping* : OrderedTable[(int, int), Tile] # tile mapping     | (coords), Tile     | meant to be mutable (data can change)
    size*    : (int, int)                     # size             | (width, length)
  Map* = object
    index* : int
    data*  : MapData
    move*  : (int, int) # cell move from (0,0)
  Session* = object # game object, to store session data
    focus* : (int, int) # coordinates of tile that is currently highlighed | (-1, -1) are default (no tile)
    mode*  : MapMode

proc getPalette* (map: Map): Palette =
    return loadPaletteFromImage(fmt"tilesets/{map.data.palette}")

proc getCellCoords* (map: Map, px_coord: (int, int)): (int, int) =
    # yields coordinates of cell from pixel coordinates (adjusting to map move)
    if px_coord[0] > 30*TL or px_coord[1] > 30*TL:
        return (-1, -1) # outside of cell window
    return (floor(px_coord[0]/TL).int + map.move[0],
            floor(px_coord[1]/TL).int + map.move[1])

proc newTile (index: int, oldata: OrderedTable[int, Tile]): Tile =
    result.index = index
    if index in oldata:
        let data    = oldata[index]
        result.name = data.name
        return result
    # default values if no data
    result.name = ""

proc parseOLDATA (oldata_file: string): OrderedTable[int, Tile] =
    # parses .oldata file and returns tile definitions in an OrderedTable
    let oldata = parseFile(fmt"tilesets/{oldata_file}")
    for tile_key in oldata.getTable.keys():
        # check for keys (todo: the proper amount of integers per map is not checked)
        for req in ["name"]:
            if oldata[tile_key].hasKey(req) == false: raise newException(Exception, fmt"Tile definition file -{oldata_file}- doesn't have all required keys! Key missing: {req}")
        result[parseInt(tile_key)] = Tile(
                                          name : oldata[tile_key]["name"].getStr()
                                          )

proc parseOLM (olm_file: string): MapData =
    # - olm_file  : .olm file containing tileset and tile data
    let olm = parseFile(fmt"maps/{olm_file}")
    # check keys before we proceed
    for k in ["tileset_img", "tileset_data", "map"]:
        if olm.hasKey(k) == false: raise newException(Exception, fmt"Map file doesn't have all required keys! Key missing: {k}")

    result.tileset = olm["tileset_img"].getStr()
    result.palette = olm["tileset_palette"].getStr()
    var defs_path  = olm["tileset_data"].getStr()
    # before files are used, we ensure they exist
    for f in [result.tileset, result.palette, defs_path]:
        if not fileExists(Path(fmt"tilesets/{f}")): raise newException(Exception, fmt"Map file directs to missing file: {f}")
    result.defs    = parseOLDATA(defs_path)
    # tile mapping
    for y, row in olm["map"].getElems().pairs:
        for x, ix in row.getElems().pairs:
            # ix = tile index; x/y = coordinates
            result.mapping[(x, y)] = newTile(ix.getInt(), result.defs)
            if result.size[1] == 0: # sets itself only once
                result.size[0] += 1
        result.size[1] += 1

proc newMap* (olm_file: string, map_index: int = 1): Map =
    # - olm_file  : .olm file containing tileset and tile data
    # - map_index : int | index 0 is for GUI/menu
    result.data  = parseOLM(olm_file)
    result.index = map_index
    result.move  = (0, 0)
    loadSpritesheet(result.index, fmt"tilesets/{result.data.tileset}", TL, TL)
    #discard loadPaletteFromImage(fmt"tilesets/{result.data.tileset}")

proc drawMap* (map: Map) =
    setPalette(getPalette(map))
    setSpritesheet(map.index)
    if len(map.data.mapping) < 900: # temporary measure, we need to just center the map and adjust it to size
        raise newException(Exception, fmt"Map file has too little tiles!") # similarly we need to limit the draw (make it via two seqs with more x/y coord system?)
                                                                # for when we would use bigger maps
    for row in 0..<30:      # 30 x 30 map area, adjusted to moved map
        for tile in 0..<30:                   # adjusted to moved map
            spr(map.data.mapping[(tile + map.move[0], row + map.move[1])].index, tile * TL, row * TL)

proc moveMap* (map: var Map, shift: (int, int)) =
    # moves the starting coordinates if the boundaries are not outside 0..map_size range
    if map.move[0] + 30 + shift[0] <= map.data.size[0] and
       map.move[1] + 30 + shift[1] <= map.data.size[1] and
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