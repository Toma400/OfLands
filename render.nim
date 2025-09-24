import nico/backends/common
import std/strformat
import std/sequtils
import std/tables
import pixie

type
  Indexes* = enum # spreadsheet/palette indexes | access their values by .ord
    XMap  = 1
    XGUI  = 2
    XGrid = 3

var PAL* = newOrderedTable[int, Palette]() # collects palettes to be later referenced, like spritesheets (indexes are meant to be equal)

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

# Helpers
proc setMapPalette* (path: string) = PAL[XMap.ord] = getPalette(path)
proc setGUIPalette* (path: string) = PAL[XGUI.ord] = getPalette(path)

proc getMapPalette* (): Palette = return PAL[XMap.ord]
proc getGUIPalette* (): Palette = return PAL[XGUI.ord]