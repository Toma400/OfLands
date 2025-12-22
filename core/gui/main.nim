import std/strformat
import std/options
import std/tables
import std/math
import questionable
import nico/gui
import nico
# OL imports
import ../../core/render/colours
import ../../core/settlement
import ../../core/entity
import ../../core/time
import ../../game
import ../../map

# default values (may be later imported from .ini, but would need adjusting GUI)
const W* = 1280
const H* = 960
# module-specific values
const sidbr_padding = TL*3 # width of sidebar (320) is 10 tiles, so with 2-tiled focus (2x scale) and 1-tiled frame (*2) it leaves us 6 (3 tiles each side)
const focus_padding = TL*4 # focus padding from -drawSidebar- adjusted to exclude frame

type
  DrawingCtx = enum # meant to not be exported
    dMAP # map (main render)
    dFOC # focus

proc drawTileContents(map: Map, ses: Session, tile: Tile, x, y: int, scale: int, context: DrawingCtx = dMAP) =
    # shared proc for `drawMap` and `drawFocus` to draw tile contents
    useSpritesheet(XMap)
    if getSeason(map.time.month) == WINTER:
        sprs(tile.wint_ix, x = x, y = y, dw = scale, dh = scale)
    else:
        sprs(tile.index,   x = x, y = y, dw = scale, dh = scale)

    if tile.road > 0 and tile.roadch:
        useSpritesheet(XSys)
        for road_piece in tile.roaddraw:
            sprs(road_piece, x = x, y = y, dw = scale, dh = scale)

    if hasObject(tile):
        if tile.location.isSome:
            let location = (!tile.location)

            if ses.mmode == FACTIONS and context == dMAP and location.owner in map.kingdoms: # keep order, short-circuiting in play
                useSpritesheet(XFac)
                sprs(location.owner - 1, x = x, y = y, dw = scale, dh = scale)
            else:
                useSpritesheet(XLoc)
                sprs(location.index, x = x, y = y, dw = scale, dh = scale)

        elif tile.settile.isSome:
            let settlement = (!tile.settile).settlem

            if ses.mmode == FACTIONS and context == dMAP and settlement.owner in map.kingdoms: # keep order, short-circuiting in play
                useSpritesheet(XFac)
                sprs(settlement.owner - 1, x = x, y = y, dw = scale, dh = scale)

            else:
                useSpritesheet(XSys)
                if tile.name in ["Shore", "Beach", "Island"]: # todo: temporary, adds platform for water tiles
                    sprs(SettlementTier.high.ord + 2, x = x, y = y, dw = scale, dh = scale)
                sprs(settlement.tier.ord + 1, x = x, y = y, dw = scale, dh = scale) # todo: SETTLEMENT_TIER.ord is temporary!

    let entity_count = getEntityList(tile).len
    if entity_count > 0:
        useSpritesheet(XSys)
        sprs(getEntityList(tile)[entity_count-1].role.ord, x = x, y = y, dw = scale, dh = scale) # uses last entity that moved onto tile

proc drawFactionInfo(map: Map, owner, player_nb: int, stype: string) =
    let name  = if owner in map.kingdoms: map.kingdoms[owner].name else: "Unowned"
    printc(name, x = H+TL*5, y = TL*10, 4)
    # banner
    if owner in map.kingdoms:
        useSpritesheet(XFac)
        sprs(owner - 1, x = H+focus_padding, y = TL*11, dw = 2, dh = 2)
    # note on player's ownership
    if owner == player_nb:
        printc(fmt"Your {stype}!", x = H+TL*5, y = TL*13, 4)

proc drawCursor(map: Map, ses: Session, ccursor: bool) =
    # replaces cursor with custom one
    if ccursor: hideMouse()
    useSpritesheet(XGUI)

    if ses.gmode == EXPLORE and ccursor:
        sprRot(3, mouse()[0], mouse()[1], 0.0)
    elif ses.gmode == ROUTE:
        if isPxWithinMap(map, mouse()):
            let cell = getCellCoords(map, mouse())
            rect(x1 = floor((cell[0]-map.move[0])*TL),   y1 = floor((cell[1]-map.move[1])*TL),
                 x2 = floor((cell[0]-map.move[0]+1)*TL), y2 = floor((cell[1]-map.move[1]+1))*TL)
        elif ccursor: # 'else + if ccursor'
            sprRot(3, mouse()[0], mouse()[1], 0.0)
    elif ses.gmode == INIT:
        if isPxWithinMap(map, mouse()):
            let cell = getCellCoords(map, mouse())
            if not canStand(map.data.mapping[cell], SETTLER): # sets square to red to indicate impossibility of placing the settler
                useColour(CWARN)
            rect(x1 = floor((cell[0]-map.move[0])*TL),   y1 = floor((cell[1]-map.move[1])*TL),
                 x2 = floor((cell[0]-map.move[0]+1)*TL), y2 = floor((cell[1]-map.move[1]+1))*TL)
            useColour(CTEXT) # resets colour to black, so it works for sidebar/text/cell that can have settler
            # draws settler
            useSpritesheet(XSys)
            spr(EntityRole.SETTLER.ord, floor((cell[0]-map.move[0])*TL), floor((cell[1]-map.move[1])*TL))
        elif ccursor: # 'else + if ccursor'
            sprRot(3, mouse()[0], mouse()[1], 0.0)

proc drawSidebar(map: Map) =
    useColour(CTEXT)

    spr(0, H, 0)                               # corner (upper left)
    for x in int((H+TL)/TL)..int((W-TL*2)/TL): # basically upper part; 992-1248 (excludes corners)
        spr(1, x*TL, 0)
    spr(2, W-TL, 0)                            # corner (upper right)
    for y in 1..int((H-TL*2)/TL):              # left part; 0-960 (excludes corners)
        spr(4, H, y*TL)
    for y in 1..int((H-TL*2)/TL):              # right part; 0-960 (excludes corners)
        spr(6, W-TL, y*TL)
    spr(8, H, H-TL)                            # corner (lower left)
    for x in int((H+TL)/TL)..int((W-TL*2)/TL): # lower part; 992-1248 (excludes corners)
        spr(9, x*TL, H-TL)
    spr(10, W-TL, H-TL)                        # corner (lower right)
    for x in int((H+TL)/TL)..int((W-TL*2)/TL): # square in the middle
      for y in 1..int((H-TL*2)/TL):
        spr(5, x*TL, y*TL)
    # focus window
    spr(0,  H+sidbr_padding,      0+sidbr_padding)
    spr(1,  H+sidbr_padding+TL,   0+sidbr_padding)
    spr(1,  H+sidbr_padding+TL*2, 0+sidbr_padding)
    spr(2,  H+sidbr_padding+TL*3, 0+sidbr_padding)
    spr(4,  H+sidbr_padding,      0+sidbr_padding+TL)
    spr(4,  H+sidbr_padding,      0+sidbr_padding+TL*2)
    spr(10, H+sidbr_padding+TL*3, 0+sidbr_padding+TL*3)
    spr(6,  H+sidbr_padding+TL*3, 0+sidbr_padding+TL)
    spr(6,  H+sidbr_padding+TL*3, 0+sidbr_padding+TL*2)
    spr(8,  H+sidbr_padding,      0+sidbr_padding+TL*3)
    spr(9,  H+sidbr_padding+TL,   0+sidbr_padding+TL*3)
    spr(9,  H+sidbr_padding+TL*2, 0+sidbr_padding+TL*3)
    # time
    printc(fmt"{map.time.day} {Month[map.time.month]} {map.time.year}, {map.time.hour}", x = H+TL*5, y = H-TL*2, 3)

proc drawFocus (map: Map, ses: Session, player_nb: int) =
    useColour(CTEXT) # black
    if isTileWithinMap(map, ses.focus):
        highlightTile(map, ses.focus)
    let tile_focused = map.data.mapping[ses.focus]

    drawTileContents(map, ses, tile_focused, H+focus_padding, 0+focus_padding, scale=2, dFOC)

    # location
    if hasObject(tile_focused):
        if tile_focused.location.isSome:
            let location = (!tile_focused.location)
            # location data
            printc(location.name, x = H+TL*5, y = TL*7, 4) # loc name | below coordinates

            drawFactionInfo(map, location.owner, player_nb, "location")

        elif tile_focused.settile.isSome:
            let settlement = (!tile_focused.settile).settlem
            # settlement data
            printc($settlement.tier, x = H+TL*5, y = TL*7, 4) # settlement tier | below coordinates
            printc(settlement.name,  x = H+TL*5, y = TL*8, 4) # settlement name | below coordinates

            drawFactionInfo(map, settlement.owner, player_nb, "settlement")

    # info box
    printc(tile_focused.name, x = H+TL*5, y = TL*1, 4) # name   | in the middle between top and focus window
    printc($ses.focus,        x = H+TL*5, y = TL*2, 3) # coords | in the middle below focus window

proc drawMap* (map: Map, ses: Session) =
    for row in 0..<MV:      # 30 x 30 map area, adjusted to moved map
        for tile in 0..<MV:                   # adjusted to moved map
            let moved_coords = (tile + map.move[0], row + map.move[1])
            let tile_drawn   = map.data.mapping[moved_coords]

            drawTileContents(map, ses, tile_drawn, tile * TL, row * TL, scale=1)

proc drawGUI* (map: Map, ses: Session, nico_gui: proc, ccursor: bool, player_nb: int) =
    useSpritesheet(XGUI)
    drawSidebar(map)
    if ses.focus != (-1, -1):
        drawFocus(map, ses, player_nb)
    G.draw(nico_gui)
    drawCursor(map, ses, ccursor)

proc drawGrid* () =
    useSpritesheet(XGrid)
    spr(0, 0, 0)
