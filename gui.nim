import std/strformat
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
    spr(3, mouse()[0], mouse()[1])
    #setColor(7)
    #rect(x1 = mouse()[0] - 10, y1 = mouse()[1] - 10,
         #x2 = mouse()[0] + 10, y2 = mouse()[1] + 10)

proc drawSidebar() =
    spr(0, 960, 0)                             # corner (upper left)
    for x in int((H+TL)/TL)..int((W-TL*2)/TL): # basically upper part; 992-1248 (excludes corners)
        spr(1, x*TL, 0)
    spr(2, W-TL, 0)                            # corner (upper right)
    for y in 1..int((H-TL*2)/TL):              # left part; 0-960 (excludes corners)
        spr(4, H, y*TL)
    for y in 1..int((H-TL*2)/TL):              # right part; 0-960 (excludes corners)
        spr(6, W-TL, y*TL)
    spr(8, H, H-TL)                         # corner (lower left)
    for x in int((H+TL)/TL)..int((W-TL*2)/TL): # lower part; 992-1248 (excludes corners)
        spr(9, x*TL, H-TL)
    spr(10, W-TL, H-TL)                        # corner (lower right)
    for x in int((H+TL)/TL)..int((W-TL*2)/TL): # square in the middle
      for y in 1..int((H-TL*2)/TL):
        spr(5, x*TL, y*TL)
    # setColor(18)
    # rectfill(x1 = H+TL, y1 = TL,
    #          x2 = W-TL, y2 = H-TL)

proc drawGUI* () =
    setPalette(getGUIPalette())
    setSpritesheet(2)
    drawSidebar()
    drawCursor()