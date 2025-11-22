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
import core/render/colours
import core/settlement
import core/entity
import kingdom
import map

const TL* = 32 # tile width/length
const MV* = 30 # map view size (default = 30)

type
  MapMode* = enum # modes used by session to filter through actions (e.g. for I/O to not focus on tile if you are now doing building)
    INIT            # init mode     | evoked when player does not have any settlements nor entities (before game)
    EXPLORE         # default mode  | clicking on tile focuses on it and allow management if tile belongs to you)
    ROUTE           # route mode    | clicking adds route node
    TRAVEL          # travel mode   | clicking directs entity to particular cell
    TRADE           # trade mode    | clicking sets destination for trade
    BUILDING        # building mode | clicking adds a construction plan
  MapData* = object
    tterrain* : string                            # terrain tileset name
    tlocs*    : string                            # location tileset name
    tfacs*    : string                            # faction tileset name
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
    bdb*   : int        # todo: temporary building helper

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

proc addSettlement* (map: var Map, tiles_occupied: seq[tuple[x, y: int]], k: var Kingdom, name: string, tier: string) =
    # helper proc, different from `map` one so it doesn't put settlement only on one tile
    var stiles = newSeq[SettlementTile]()
    for tile in tiles_occupied:
        let tile_read_only = map.data.mapping[tile]
        if not hasObject(tile_read_only) and canSettlementExist(tile_read_only): # checks if tile is occupied + if settlement can be put
            add(stiles, newSettlementTile(tile))
    if stiles.len > 0:
        for stile in stiles:
            map.data.mapping[stile.coords].settile = stile.some       # binds SettlementTile to Tile
        k.settlems.add(newSettlement(name, stiles, k.number, TIER_STR[tier])) # binds Settlement to Kingdom

proc parseTerrainOLDATA (oldata_file: string): OrderedTable[int, TilePrefab] =
    # parses .oldata file and returns tile definitions in an OrderedTable
    let oldata = parseFile(fmt"tilesets/{oldata_file}")
    for cat in oldata.getTable.keys():
        if cat == "tile":
            for tile_key in oldata["tile"].getTable.keys():
                result[parseInt(tile_key)] = newTilePrefab( # initialises prefab, using default values if key not found
                                                           tname   = oldata["tile"][tile_key]["name"].getStr(""),
                                                           mv_cost = oldata["tile"][tile_key]["mv_cost"].getInt(),
                                                           tbase   = oldata["tile"][tile_key]["tbase"].getStr(""),
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

proc parseOLM (olm: TomlValueRef): MapData =
    # - olm : .olm file parsed by `newMap` into TomlValueRef object
    # check keys before we proceed
    for k in ["tileset_terrain", "tileset_locations", "tileset_factions", "tileset_system", "data_terrain", "data_locations", "terrain"]:
        if olm.hasKey(k) == false: raise newException(Exception, fmt"Map file doesn't have all required keys! Key missing: {k}")

    result.tterrain = olm["tileset_terrain"].getStr()
    result.tlocs    = olm["tileset_locations"].getStr()
    result.tfacs    = olm["tileset_factions"].getStr()
    result.tsys     = olm["tileset_system"].getStr()
    var tdefs_path  = olm["data_terrain"].getStr()
    var ldefs_path  = olm["data_locations"].getStr()
    # before files are used, we ensure they exist
    for f in [result.tterrain, result.tlocs, result.tsys, tdefs_path, ldefs_path]:
        if not fileExists(Path(fmt"tilesets/{f}")): raise newException(Exception, fmt"Map file directs to missing file: {f}")
    result.tdefs = parseTerrainOLDATA(tdefs_path)
    result.ldefs = parseLocationOLDATA(ldefs_path)
    # road mapping
    var roads_mapping: Table[tuple[x, y: int], int]
    proc getRoad (mapping: Table[tuple[x, y: int], int], coord: tuple[x, y: int]): int =
        if coord in mapping: return mapping[coord]
        else:                return 0
    if olm.hasKey("roads"):
        for y, row in olm["roads"].getElems().pairs:
            for x, ix in row.getElems().pairs():
                # ix = road index; x/y = coordinates
                if ix.getInt() > 0: roads_mapping[(x, y)] = ix.getInt()
    # tile mapping
    for y, row in olm["terrain"].getElems().pairs:
        for x, ix in row.getElems().pairs:
            # ix = tile index; x/y = coordinates
            result.mapping[(x, y)] = newTile(result.tdefs, ix.getInt(), (x, y), getRoad(roads_mapping, (x, y)))
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

proc parseSettlements (distribution: TomlValueRef): OrderedTable[int, seq[tuple [x, y: int]]] =
    # parses .olf's 'settlements' value, does not create settlements alone
    for y, row in distribution.getElems().pairs:
        for x, ix in row.getElems().pairs:
            # ix = settlement index; x/y = coordinates
            if ix.getInt() != -1: # no settlement
                if ix.getInt() in result:
                    result[ix.getInt()].add((x, y))
                else: result[ix.getInt()] = @[(x, y)]

proc parseFactions* (ffile: string, map: var Map, player_k_nb: int, player_k_nm: string): OrderedTable[int, Kingdom] =
    # parses .olf file and creates table of kingdoms
    # if player number doesn't match existing kingdom, default one (`def`) is made
    let def = newKingdom(name   = player_k_nm,
                         number = player_k_nb)
    # ---
    if ffile == "" or not fileExists(Path(fmt"maps/{ffile}")):
        result[player_k_nb] = def
        return result
    else:
        let olf = parseFile(fmt"maps/{ffile}")
        if olf.hasKey("kingdom"):
            for index in olf["kingdom"].getTable.keys():
                let ix    = parseInt(index)
                let kdata = olf["kingdom"][index]
                # data
                let knm = if kdata.hasKey("name"):        kdata["name"].getStr()        else: ""
                let kds = if kdata.hasKey("description"): kdata["description"].getStr() else: ""
                var kst = (0, 0) # default
                if kdata.hasKey("start_coordinates"):
                    let coords = kdata["start_coordinates"].getElems()
                    if len(coords) == 2:
                        kst = (coords[0].getInt(), coords[1].getInt())

                result[ix] = newKingdom(name   = knm,
                                        number = ix,
                                        start  = kst,
                                        descr  = kds)

            if olf.hasKey("map") and olf.hasKey("settlement"):
                if olf["map"].hasKey("settlements"):
                    let settlement_library = parseSettlements(olf["map"]["settlements"])
                    for index in olf["settlement"].getTable.keys():
                        let ix = parseInt(index)
                        if ix in settlement_library: # skips the settlement if not found on map
                            let sdata = olf["settlement"][index]
                            # check for values a) existing b) not having no value
                            if sdata["tier"].getStr("") != "" and sdata["kingdom"].getInt(0) != 0:
                                # data setup
                                let knb = sdata["kingdom"].getInt()
                                let snm = if sdata.hasKey("name"): sdata["name"].getStr() else: "" # the only optional value
                                let str = sdata["tier"].getStr()

                                var tiles_occupied = newSeq[tuple[x, y: int]]()
                                for tile_coords in settlement_library[ix]:
                                    add(tiles_occupied, tile_coords)
                                addSettlement(map, tiles_occupied, result[knb], snm, str)

            if player_k_nb in result:
                return result
        # # "else" for no 'kingdom' key or player not being registered is handled below
    result[player_k_nb] = def

    # TODO! SCAN FOR CITIES COULD FIRST GATHER CITIES TOGETHER, as in:
    # let table = emptyTable[int, seq[tuple (x, y: int)]]
    # for x in map:
    #   for y in map[x]:
    #      if (x, y).hasSettlement: table[].add((x, y))
    #
    # Tiled would export it to TOML like this:
    # [settlement.1]
    # data = ...
    #
    # and later we would get properties from tileset by going from table:
    # for i, coords in table:
    #     var seq = newSeq[SettlementTile]()
    #     for c in coords.len:
    #        seq.add(newSettlement(c)
    #     registerSettlement(data = data, coords = seq)

proc parseDate (olm: TomlValueRef): tuple[year, month, day, hour: int] =
    result.hour = 1 # default hour no matter the settings
    if olm.hasKey("start_date"):
        let dates = olm["start_date"].getElems()
        if len(dates) >= 3:
            return (year: dates[0].getInt(), month: dates[1].getInt(), day: dates[2].getInt(), hour: 1)
        elif len(dates) == 2:
            return (year: dates[0].getInt(), month: dates[1].getInt(), day: 1,                 hour: 1)
        elif len(dates) == 1:
            return (year: dates[0].getInt(), month: 1,                 day: 1,                 hour: 1)
    return (year: 1, month: 1, day: 1, hour: 1)

proc getInitialCoords (olm: TomlValueRef, p_kingdom: Kingdom): (int, int) =
    if p_kingdom.start != (0, 0):
        return p_kingdom.start
    if olm.hasKey("start_coordinates"):
        let coords = olm["start_coordinates"].getElems()
        if len(coords) == 2:
            return (coords[0].getInt(), coords[1].getInt())
    return (0, 0)

proc getFactionFile* (olm: TomlValueRef): string =
    if olm.hasKey("factions"):
        return olm["factions"].getStr()
    return "" # aka "no file provided, start with only player"

proc newMap* (olm_file: string, player_kingdom: tuple[nb: int, nm: string]): Map =
    # - olm_file  : .olm file containing tileset and tile data
    # - map_index : int | index 0 is for GUI/menu
    let olm         = parseFile(fmt"maps/{olm_file}")
    let pix         = if player_kingdom.nb > 0: player_kingdom.nb else: 1 # checks for positive number

    result.data     = parseOLM(olm)
    result.kingdoms = parseFactions(getFactionFile(olm), result, pix, player_kingdom.nm)
    result.move     = getInitialCoords(olm, result.kingdoms[pix])
    result.time     = parseDate(olm)
    if result.time.year < 1 or result.time.month < 1 or result.time.day < 1:
        raise newException(Exception, fmt"Game has incorrect date set. Date needs every value (year/month/day) be positive number!")
    if len(result.data.mapping) < MV*MV: # temporary measure, we will eventually need to just center the map and adjust it to size in -drawMap-
        raise newException(Exception, fmt"Map file has too little tiles!")

proc drawMap* (map: Map) =
    # IMPORTANT: needs to also be updated in `gui.nim` focus render
    for row in 0..<MV:      # 30 x 30 map area, adjusted to moved map
        for tile in 0..<MV:                   # adjusted to moved map
            let moved_coords = (tile + map.move[0], row + map.move[1])
            let tile_drawn   = map.data.mapping[moved_coords]
            useSpritesheet(XMap)
            spr(tile_drawn.index, tile * TL, row * TL)
            # road drawing
            if map.data.mapping[moved_coords].road > 0 and map.data.mapping[moved_coords].roadch:
                useSpritesheet(XSys)
                for road_piece in map.data.mapping[moved_coords].roaddraw:
                    spr(road_piece, tile * TL, row * TL)
            #     discard # here would be another `spr` that draws road on top, using also .roadcnn to determine tile
            if tile_drawn.location.isSome:
                useSpritesheet(XLoc)
                spr((!tile_drawn.location).index, tile * TL, row * TL)
            elif tile_drawn.settile.isSome:
                useSpritesheet(XSys)
                if tile_drawn.name in ["Shore", "Beach", "Island"]: # todo: temporary, adds platform for water tiles
                    spr(5, tile * TL, row * TL)
                spr((!tile_drawn.settile).settlem.tier.ord + 1, tile * TL, row * TL) # TODO: temporary!
            let entity_count = getEntityList(tile_drawn).len
            if entity_count > 0:
                useSpritesheet(XSys)
                spr(getEntityList(tile_drawn)[entity_count-1].role.ord, tile * TL, row * TL) # uses last entity that moved onto tile

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
    result.bdb   = -1 # no selection (default)