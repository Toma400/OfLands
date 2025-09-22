import std/strformat
import std/strutils
import std/tables
import std/files
import std/paths
import parsetoml
# nico specifics
import nico

const TL = 32 # tile width/length

type
  Tile* = object
    name* : string
  MapData* = object
    tileset* : string                  # tileset name
    defs*    : OrderedTable[int, Tile] # tile definitions
    mapping* : seq[int]                # tile mapping
  Map* = object
    index* : int
    data*  : MapData
  Indexes* = enum # spreadsheet indexes
    XMap      = 1
    XFeatures = 2
    XGrid     = 3

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
    var defs_path  = olm["tileset_data"].getStr()
    # before files are used, we ensure they exist
    for f in [result.tileset, defs_path]:
        if not fileExists(Path(fmt"tilesets/{f}")): raise newException(Exception, fmt"Map file directs to missing file: {f}")
    result.defs    = parseOLDATA(defs_path)
    # tile mapping
    for i in olm["map"].getElems():
        result.mapping.add(i.getInt())

proc newMap* (olm_file: string, map_index: int = 1): Map =
    # - olm_file  : .olm file containing tileset and tile data
    # - map_index : int | index 0 is for GUI/menu
                        # index -1 is grid
    result.data  = parseOLM(olm_file)
    result.index = map_index
    loadSpritesheet(result.index, fmt"tilesets/{result.data.tileset}", TL, TL)
    #discard loadPaletteFromImage(fmt"tilesets/{result.data.tileset}")

proc drawMap* (map: Map) =
    setSpritesheet(map.index)
    if len(map.data.mapping) < 900: # temporary measure, we need to just center the map and adjust it to size
        raise newException(Exception, fmt"Map file has too little tiles!") # similarly we need to limit the draw (make it via two seqs with more x/y coord system?)
                                                                # for when we would use bigger maps
    for row in 0..30: # 30 x 30 map area
        for tile in 0..30:
            let tile_index = row*30 + tile
            if tile_index < 900:
                spr(map.data.mapping[tile_index], tile * TL, row * TL)

    #setSpritesheet(3) # grid drawing
    #spr(0, 0, 0)

proc drawGrid* () =
    discard