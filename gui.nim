import std/strformat
import std/options
import std/tables
import std/math
import questionable
# OL imports
import core/render/colours
import core/settlement
import core/entity
import core/time
import nico
import game
import map

# default values (may be later imported from .ini, but would need adjusting GUI)
const W* = 1280
const H* = 960

proc drawCursor(map: Map, ses: Session, ccursor: bool) =
    # replaces cursor with custom one
    if ccursor: hideMouse()

    if ses.mode == EXPLORE and ccursor:
        sprRot(3, mouse()[0], mouse()[1], 0.0)
    elif ses.mode == ROUTE:
        if isPxWithinMap(map, mouse()):
            let cell = getCellCoords(map, mouse())
            rect(x1 = floor((cell[0]-map.move[0])*TL),   y1 = floor((cell[1]-map.move[1])*TL),
                 x2 = floor((cell[0]-map.move[0]+1)*TL), y2 = floor((cell[1]-map.move[1]+1))*TL)
        elif ccursor: # 'else + if ccursor'
            sprRot(3, mouse()[0], mouse()[1], 0.0)
    elif ses.mode == INIT:
        if isPxWithinMap(map, mouse()):
            let cell = getCellCoords(map, mouse())
            if not canStand(map.data.mapping[cell], SETTLER): # sets square to red to indicate impossibility of placing the settler
                setColor(1)
            rect(x1 = floor((cell[0]-map.move[0])*TL),   y1 = floor((cell[1]-map.move[1])*TL),
                 x2 = floor((cell[0]-map.move[0]+1)*TL), y2 = floor((cell[1]-map.move[1]+1))*TL)
            setColor(0) # resets colour to black, so it works for sidebar/text/cell that can have settler
            # draws settler
            useSpritesheet(XSys)
            spr(EntityRole.SETTLER.ord, floor((cell[0]-map.move[0])*TL), floor((cell[1]-map.move[1])*TL))
        elif ccursor: # 'else + if ccursor'
            sprRot(3, mouse()[0], mouse()[1], 0.0)

proc drawSidebar(map: Map) =
    let focus_padding = TL*3 # width of sidebar (320) is 10 tiles, so with 2-tiled focus (2x scale) and 1-tiled frame (*2) it leaves us 6 (3 tiles each side)
    setColor(0)

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
    spr(0,  H+focus_padding,      0+focus_padding)
    spr(1,  H+focus_padding+TL,   0+focus_padding)
    spr(1,  H+focus_padding+TL*2, 0+focus_padding)
    spr(2,  H+focus_padding+TL*3, 0+focus_padding)
    spr(4,  H+focus_padding,      0+focus_padding+TL)
    spr(4,  H+focus_padding,      0+focus_padding+TL*2)
    spr(10, H+focus_padding+TL*3, 0+focus_padding+TL*3)
    spr(6,  H+focus_padding+TL*3, 0+focus_padding+TL)
    spr(6,  H+focus_padding+TL*3, 0+focus_padding+TL*2)
    spr(8,  H+focus_padding,      0+focus_padding+TL*3)
    spr(9,  H+focus_padding+TL,   0+focus_padding+TL*3)
    spr(9,  H+focus_padding+TL*2, 0+focus_padding+TL*3)
    # time
    printc(fmt"{map.time.day} {Month[map.time.month]} {map.time.year}, {map.time.hour}", x = H+TL*5, y = H-TL*2, 3)

proc drawFocus (map: Map, ses: Session, player_nb: int) =
    let focus_padding = TL*4 # focus padding from -drawSidebar- adjusted to exclude frame
    useSpritesheet(XMap)
    setColor(0) # black
    if isTileWithinMap(map, ses.focus):
        highlightTile(map, ses.focus)
    let tile_focused = map.data.mapping[ses.focus]
    sprs(tile_focused.index, x = H+focus_padding, y = 0+focus_padding, dw = 2, dh = 2) # draw highlighted tile in 2x scale

    # location
    # IMPORTANT: needs to also be updated in `game.nim` render
    if hasObject(tile_focused):
        if tile_focused.location.isSome:
            useSpritesheet(XLoc)
            let location = (!tile_focused.location)
            sprs(location.index, x = H+focus_padding, y = 0+focus_padding, dw = 2, dh = 2)
            # location data
            printc(location.name, x = H+TL*5, y = TL*7, 4) # loc name | below coordinates
            # location name
            let owner = location.owner
            let name  = if owner in map.kingdoms: map.kingdoms[owner].name else: "Unowned"
            printc(name, x = H+TL*5, y = TL*10, 4)
            if owner in map.kingdoms:
                useSpritesheet(XFac)
                sprs(owner - 1, x = H+focus_padding, y = TL*12, dw = 2, dh = 2) # draw faction banner in 2x scale
            if owner == player_nb:
                printc("Your location!", x = H+TL*5, y = TL*13, 4)

        elif tile_focused.settile.isSome:
            useSpritesheet(XSys)
            let settlement = (!tile_focused.settile).settlem
            sprs(settlement.tier.ord + 1, x = H+focus_padding, y = 0+focus_padding, dw = 2, dh = 2) # todo: SETTLEMENT_TIER.ord is temporary!
            # settlement data
            printc($settlement.tier, x = H+TL*5, y = TL*7, 4) # settlement tier | below coordinates
            printc(settlement.name,  x = H+TL*5, y = TL*8, 4) # settlement name | below coordinates
            # kingdom name
            let owner = settlement.knb
            let kname = if owner in map.kingdoms: map.kingdoms[owner].name else: "Unowned"
            printc(kname, x = H+TL*5, y = TL*10, 4)
            if owner in map.kingdoms:
                useSpritesheet(XFac)
                sprs(owner - 1, x = H+focus_padding, y = TL*11, dw = 2, dh = 2) # draw faction banner in 2x scale
            if owner == player_nb:
                printc("Your settlement!", x = H+TL*5, y = TL*14, 4)

    let entity_count = getEntityList(tile_focused).len
    if entity_count > 0:
        useSpritesheet(XSys)
        sprs(getEntityList(tile_focused)[entity_count-1].role.ord, x = H+focus_padding, y = 0+focus_padding, dw = 2, dh = 2) # uses last entity that moved onto tile

    # info box
    printc(tile_focused.name, x = H+TL*5, y = TL*1, 4) # name   | in the middle between top and focus window
    printc($ses.focus,        x = H+TL*5, y = TL*2, 3) # coords | in the middle below focus window

proc drawGUI* (map: Map, ses: Session, ccursor: bool, player_nb: int) =
    useSpritesheet(XGUI)
    drawSidebar(map)
    drawCursor(map, ses, ccursor)
    if ses.focus != (-1, -1):
        drawFocus(map, ses, player_nb)

proc drawGrid* () =
    useSpritesheet(XGrid)
    #setSpritesheet(3) # grid drawing
    spr(0, 0, 0)