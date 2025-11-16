import nico/backends/common
import std/strformat
import std/sequtils
import std/tables
import pixie
import nico

type
  Indexes* = enum # spreadsheet indexes | access their values by .ord
    XMap  = 1
    XLoc  = 2
    XFac  = 3
    XGUI  = 4
    XSys  = 5
    XGrid = 6

proc basePalette (): Palette =
    const COL = [
        (55.uint8,  55.uint8, 33.uint8), # 0 | pure black
        (225.uint8, 6.uint8,  0.uint8),  # 1 | bright red
#        (0.uint8,   0.uint8,  0.uint8)   # 2 | pure pure black (so the skipping can be done without losing colour)
    ]
    for i, c in COL:
        result.size    = i+1
        result.data[i] = c

proc getPalette (img_path: string): Palette =
    # yields palette directly from the image (supports entire images)
    let img  = readImage(img_path)
    var cols = newSeq[tuple[r, g, b: uint8]]()
    for px in img.data:
        if px.a == 255: # not sure if needed # turns out it is lol
            cols.add((px.r, px.g, px.b))
    cols = deduplicate(cols) # overwrites
    #cols = filter(cols, proc(x: tuple[r, g, b: uint8]): bool = x != (0.uint8, 0.uint8, 0.uint8))
    result.size = len(cols)
    for i, col in cols.pairs:
        result.data[i] = col
    # echo "START"
    # echo img_path
    # echo result.size
    # for i, c in result.data:
    #     echo fmt"{i}) {c.r}, {c.g}, {c.b}"
    # echo "END"

# proc deduplicatePalette (p: Palette): Palette =
#     var outs = newSeq[tuple[r, g, b: uint8]]()
#     for i, col in p.data:
#         outs.add(col)
#     outs = deduplicate(outs)
#     result.size = len(outs)
#     for i, col in outs.pairs:
#         result.data[i] = col

proc `+` (pals: varargs[Palette]): Palette =
    var needle = 0
    for i, pal in pals:
        result.size = result.size + pal.size
        if result.size >= maxPaletteSize:
            raise newException(Exception, "Map has too many colours! Please ensure that both map and GUI (4) have up to 4096 colours!")
        for i, dt in pal.data:
            if dt == (0.uint8, 0.uint8, 0.uint8): break # marks end of currently iterated palette
            result.data[needle] = (dt.r, dt.g, dt.b)
            needle += 1
    # todo: may be useful in the future -- result.data = deduplicate(result.data) # cuts any repeated colours

proc registerPalettes* (map: string, loc: string, fac: string, gui: string, sys: string) =
    # ensures the correct indexes exist
    setPalette(basePalette() + getPalette(map) + getPalette(loc) + getPalette(fac) + getPalette(gui) + getPalette(sys)) # loads palettes, merge them and sets as currently used

proc useSpritesheet* (ix: Indexes) =
    # sets both palette and spritesheet together to be used
    case ix:
      of XMap:  setSpritesheet(XMap.ord)
      of XLoc:  setSpritesheet(XLoc.ord)
      of XFac:  setSpritesheet(XFac.ord)
      of XGUI:  setSpritesheet(XGUI.ord)
      of XSys:  setSpritesheet(XSys.ord)
      of XGrid: setSpritesheet(XGrid.ord)