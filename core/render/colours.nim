import nico/backends/common
import std/strformat
import std/strutils
import std/sequtils
import std/tables
import parsetoml
import os
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
  BaseCols* = enum # if you edit any values here, make sure to also adjust `basePalette.COLS`
    # base OL colours
    CTEXT = "text"
    CWARN = "warn"
    # Nico's GUI : text
    CTFLT = "text_flt" # flat
    CTINS = "text_ins" # inset
    CTOTS = "text_ots" # outset
    CTDIS = "text_dis" # disabled

var col_referrer* : OrderedTable[BaseCols, int] # allows for quick referencing to Palette grid (int = index) with adjustment to repeated values

proc basePalette (referrer: var OrderedTable[BaseCols, int]): Palette =
    # default values - get replaced by .toml values later
    var COLS = {
        "text":     (0.uint8,     0.uint8,   0.uint8), # 0 | pure black
        "warn":     (225.uint8,   6.uint8,   0.uint8), # 1 | bright red
        "text_flt": (0.uint8,     0.uint8,   0.uint8), #
        "text_ins": (100.uint8,   0.uint8,   0.uint8), #
        "text_ots": (0.uint8,     0.uint8,   0.uint8), #
        "text_dis": (128.uint8, 128.uint8, 128.uint8), # 2 | gray
    }.toOrderedTable

    if existsFile("gui/gui.toml"): # if it doesn't, defaults are applied
        let base = parseFile("gui/gui.toml")
        for key in base.getTable().keys():
            if key in COLS:
                let sseq = base[key].getElems()
                if len(sseq) == 3: # check if all values exist
                    COLS[key] = (
                        uint8(sseq[0].getInt()), # r
                        uint8(sseq[1].getInt()), # g
                        uint8(sseq[2].getInt())  # b
                    )

    var palcols = newSeq[tuple[r, g, b: uint8]]()
    for key in COLS.keys():
        palcols.add(COLS[key])
    palcols = deduplicate(palcols)
    for i in 0..len(palcols) - 1:
        result.data[i] = palcols[i]
        result.size   += 1

    for ckind in BaseCols.low..BaseCols.high: # sets the indexes, so that these values can be accessed later
        referrer[ckind] = find(palcols, COLS[$ckind])

# proc basePalette (): Palette =
#     const COL = [
#         #(55.uint8,  55.uint8, 33.uint8), # 0 | pure black
#         (0.uint8, 0.uint8, 0.uint8),
#         (225.uint8, 6.uint8,  0.uint8),  # 1 | bright red
# #        (0.uint8,   0.uint8,  0.uint8)   # 2 | pure pure black (so the skipping can be done without losing colour)
#     ]
#     for i, c in COL:
#         result.size    = i+1
#         result.data[i] = c
#
#     # for i, c in result.data:
#     #     if i < result.size:
#     #         echo fmt"{i + 1}) {c.r}, {c.g}, {c.b}"

proc getPalette (img_path: string): Palette =
    # yields palette directly from the image (supports entire images)
    let img  = readImage(img_path)
    var cols = newSeq[tuple[r, g, b: uint8]]()
    for px in img.data:
        if px.a == 255: # not sure if needed # turns out it is lol
            cols.add((px.r, px.g, px.b))
    cols = deduplicate(cols) # overwrites
    #todo: echo "Analysing palette: " & img_path
    #todo: echo "Does it have pure black? (0, 0, 0)"
    #todo: echo (0.uint8, 0.uint8, 0.uint8) in cols
    #cols = filter(cols, proc(x: tuple[r, g, b: uint8]): bool = x != (0.uint8, 0.uint8, 0.uint8))
    result.size = len(cols)
    for i, col in cols.pairs:
        result.data[i] = col
    #todo: echo "START : " & img_path
    #todo: echo result.size
    #todo: below
    # for i, c in result.data:
    #     if i < result.size:
    #         echo fmt"{i + 1}) {c.r}, {c.g}, {c.b}"
    #todo: echo "END"

# proc getPalette (img_paths: varargs[string]): Palette =
#     # yields palette directly from the image (supports entire images)
#     var cols = newSeq[tuple[r, g, b: uint8]]()
#
#     for img_path in img_paths:
#         let img  = readImage(img_path)
#         for px in img.data:
#             if px.a == 255: # not sure if needed # turns out it is lol
#                 cols.add((px.r, px.g, px.b))
#     cols = deduplicate(cols) # overwrites
#     # echo "Analysing palette: " & img_path
#     # echo "Does it have pure black? (0, 0, 0)"
#     # echo (0.uint8, 0.uint8, 0.uint8) in cols
#     #cols = filter(cols, proc(x: tuple[r, g, b: uint8]): bool = x != (0.uint8, 0.uint8, 0.uint8))
#     result.size = len(cols)
#     for i, col in cols.pairs:
#         result.data[i] = col
#     # echo "START : " & img_path
#     # echo result.size
#     # for i, c in result.data:
#     #     if i < result.size:
#     #         echo fmt"{i + 1}) {c.r}, {c.g}, {c.b}"
#     # echo "END"

# proc deduplicatePalette (p: Palette): Palette =
#     let old_size = p.size
#     var outs = newSeq[tuple[r, g, b: uint8]]()
#     for i, col in p.data:
#         outs.add(col)
#     outs = deduplicate(outs)
#     result.size = len(outs)
#     for i, col in outs.pairs:
#         result.data[i] = col
#     echo "FINAL NUMBER: " & $result.size
#     echo "(removed " & $(old_size-result.size) & " duplicates)"

# proc `+` (pals: varargs[Palette]): Palette =
#     # var needle = 0
#     # for i, pal in pals:
#     #     result.size = result.size + pal.size
#     #     if result.size >= maxPaletteSize:
#     #         raise newException(Exception, "Map has too many colours! Please ensure that both map and GUI (4) have up to 4096 colours!")
#     #     for i, dt in pal.data:
#     #         if dt == (0.uint8, 0.uint8, 0.uint8): break # marks end of currently iterated palette
#     #         result.data[needle] = (dt.r, dt.g, dt.b)
#     #         needle += 1
#     # # todo: may be useful in the future -- result.data = deduplicate(result.data) # cuts any repeated colours
#     var needle = 0
#     for i, pal in pals:
#         # result.size = result.size + pal.size
#         # if result.size >= maxPaletteSize:
#         #     raise newException(Exception, "Map has too many colours! Please ensure that both map and GUI (4) have up to 4096 colours!")
#         for i, dt in pal.data:
#             if i >= pal.size: break
#             result.data[needle] = (dt.r, dt.g, dt.b)
#             needle += 1
#     result.size = needle
#     echo "MERGED NUMBER: " & $needle

proc `+` (p1, p2: Palette): Palette =
    var needle = 0
    for i, dt in p1.data:
        if i >= p1.size: break
        result.data[needle] = (dt.r, dt.g, dt.b)
        needle += 1
    for i, dt in p2.data:
        if i >= p2.size: break
        result.data[needle] = (dt.r, dt.g, dt.b)
        needle += 1
    result.size = needle
    #todo: echo "MERGED NUMBER: " & $needle

proc registerPalettes* (cref: var OrderedTable[BaseCols, int], map: string, loc: string, fac: string, gui: string, sys: string) =
    # ensures the correct indexes exist
    #setPalette(basePalette() + getPalette(map) + getPalette(loc) + getPalette(fac) + getPalette(gui) + getPalette(sys)) # loads palettes, merge them and sets as currently used
    #setPalette(deduplicatePalette(basePalette() + getPalette(map) + getPalette(fac) + getPalette(gui) + getPalette(sys)))# + getPalette(loc)))
    setPalette(basePalette(cref) + getPalette(map) + getPalette(fac) + getPalette(gui) + getPalette(sys))# + getPalette(loc))
    #setPalette(basePalette() + getPalette(map, fac, gui, sys, loc))

proc useSpritesheet* (ix: Indexes) =
    # sets both palette and spritesheet together to be used
    case ix:
      of XMap:  setSpritesheet(XMap.ord)
      of XLoc:  setSpritesheet(XLoc.ord)
      of XFac:  setSpritesheet(XFac.ord)
      of XGUI:  setSpritesheet(XGUI.ord)
      of XSys:  setSpritesheet(XSys.ord)
      of XGrid: setSpritesheet(XGrid.ord)

proc useColour* (bc: BaseCols) =
    # equivalent to Nico's `setcolor`, but uses referrer values instead of ambigue numbers
    setColor(col_referrer[bc])