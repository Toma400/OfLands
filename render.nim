import nico/backends/common
import std/strformat
import std/sequtils
import std/tables
import pixie
import nico

type
  Indexes* = enum # spreadsheet/palette indexes | access their values by .ord
    XMap  = 1
    XGUI  = 2
    XGrid = 3

proc basePalette (): Palette =
    const COL = [
        (55.uint8, 55.uint8, 33.uint8)
    ]
    for i, c in COL:
        result.size    = i+1
        result.data[i] = c

proc getPalette (img_path: string): Palette =
    # yields palette directly from the image (supports entire images)
    let img  = readImage(img_path)
    var cols = newSeq[tuple[r, g, b: uint8]]()
    for px in img.data:
        if px.a == 255: # not sure if needed
            cols.add((px.r, px.g, px.b))
    cols = deduplicate(cols) # overwrites
    result.size = len(cols)
    for i, col in cols.pairs:
        result.data[i] = col

proc `+` (pals: varargs[Palette]): Palette =
    var needle = 0
    for i, pal in pals:
        result.size = result.size + pal.size
        if result.size >= maxPaletteSize:
            raise newException(Exception, "Map has too many colours! Please ensure that both map and GUI (4) have up to 255 colours!")
        for i, dt in pal.data:
            if dt == (0.uint8, 0.uint8, 0.uint8): break # marks end of currently iterated palette
            result.data[needle] = (dt.r, dt.g, dt.b)
            needle += 1

proc registerPalettes* (map: string, gui: string) =
    # ensures the correct indexes exist
    setPalette(basePalette() + getPalette(map) + getPalette(gui)) # loads palettes, merge them and sets as currently used

proc useSpritesheet* (ix: Indexes) =
    # sets both palette and spritesheet together to be used
    case ix:
      of XMap:  setSpritesheet(XMap.ord)
      of XGUI:  setSpritesheet(XGUI.ord)
      of XGrid: setSpritesheet(XGrid.ord)