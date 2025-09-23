import std/strformat
import std/tables
import nico
import game

# default values (may be later imported from .ini, but would need adjusting GUI)
const W* = 1280
const H* = 960

proc getGUIPalette* (): Palette =
    return loadPaletteFromImage(fmt"gui/gui_palette.png")

proc drawCursor() =
    # replaces cursor with custom one
    hideMouse()
    sprRot(3, mouse()[0], mouse()[1], 0.0)
    #setColor(7)
    #rect(x1 = mouse()[0] - 10, y1 = mouse()[1] - 10,
         #x2 = mouse()[0] + 10, y2 = mouse()[1] + 10)

proc drawSidebar() =
    let focus_padding = TL*3 # width of sidebar (320) is 10 tiles, so with 2-tiled focus (2x scale) and 1-tiled frame (*2) it leaves us 6 (3 tiles each side)

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

proc drawFocus (map: Map, ses: Session) =
    let focus_padding = TL*4 # focus padding from -drawSidebar- adjusted to exclude frame
    highlightTile(map, ses.focus)
    setPalette(getPalette(map)) # gets palette for focus tile
    setSpritesheet(1)
    sprs(map.data.mapping[ses.focus].index, x = H+focus_padding, y = 0+focus_padding, dw = 2, dh = 2) # draw highlighted tile in 2x scale
    setPalette(getGUIPalette()) # resets the palette to GUI one
    # info box
    printc(map.data.mapping[ses.focus].name, x = H+TL*5, y = TL*2, 4) # name   | in the middle between top and focus window
    printc($ses.focus,                       x = H+TL*5, y = TL*7, 3) # coords | in the middle below focus window

proc drawGUI* (map: Map, ses: Session) =
    setPalette(getGUIPalette())
    setSpritesheet(2)
    drawSidebar()
    drawCursor()
    if ses.focus != (-1, -1):
        drawFocus(map, ses)

proc drawGrid* () =
    setSpritesheet(3) # grid drawing
    spr(0, 0, 0)