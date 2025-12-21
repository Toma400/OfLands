import std/private/osfiles
import std/private/osdirs
import std/strformat
import std/sequtils
import std/strutils
import std/parsecfg
import std/osproc
import std/tables
import std/math
import parsetoml
import nigui
import pixie
import os

import kingdom
import game

# TODO
# - "new Faction" with name TextArea

proc facToSeq(ot: OrderedTable[int, Kingdom]): seq[string] =
    for i, k in ot.pairs():
        result.add(k.name)

proc setDescr(ta: TextArea, k: Kingdom) =
    ta.text = ""
    if k.descr != "":
        ta.addLine(k.descr)
        ta.addLine("")
    if len(k.settlems) > 0:
        ta.addLine("List of settlements:")
        for s in k.settlems:
            ta.addLine("- " & s.name)

proc setBanner(src: common.Image, kingdom_nb: int, file_index: int) =
    var img_out = newImage(32, 32)
    let
      kd_map_id = kingdom_nb - 1
      row_tiles = (src.width/32).int
      x_start = if kingdom_nb mod row_tiles != 0: (kingdom_nb mod row_tiles) - 1  else: row_tiles - 1
      y_start = if kingdom_nb mod row_tiles != 0: floorDiv(kingdom_nb, row_tiles) else: floorDiv(kingdom_nb, row_tiles) - 1
    let # coordinates
      xc_start = x_start*32
      yc_start = y_start*32
      xc_end   = xc_start+32-1 # minus to accomodate that range counts xc_start/yc_start, so needs last position excluded (for programming 0...n-1 indexing system)
      yc_end   = yc_start+32-1
    for x in xc_start..xc_end:
      for y in yc_start..yc_end:
        if not inside(src, x, y):
            return # return early, skip writing file
        img_out[x - xc_start, y - yc_start] = src[x, y] # write on 0..32 the contents of `src`
    img_out = resize(img_out, 64, 64)
    createDir("_temp")
    writeFile(img_out, fmt"_temp/banner_{file_index}_used.png")

proc setMapInfo(map: Map, sl, kcl, scl: var Label) =
    sl.text  = fmt"| Map size: {map.data.size[0]}, {map.data.size[1]}"
    kcl.text = fmt"| Kingdoms: {len(map.kingdoms)}"
    var scount = 0
    for _, k in map.kingdoms.pairs:
      for s in k.settlems: scount += 1
    scl.text = fmt"| Settlements: {scount}"

let maps   = toSeq(walkFiles("maps/*.olm"))
if existsDir("_temp"):
    removeDir("_temp")

# data
var cfg    = loadConfig("oflands.ini")
let map_nm = getSectionValue(cfg, "", "map")
var map_dt = newMap(olm_file       = map_nm,
                    player_kingdom = (nb: 0,
                                      nm: getSectionValue(cfg, "", "kingdom")),
                    )

var banners = if existsFile(fmt"tilesets/{map_dt.data.tfacs}"): readImage(fmt"tilesets/{map_dt.data.tfacs}") else: nil
var ban_tab : OrderedTable[int, nigui.Image]
var ban_ix  = 0

# app run
app.init()
var window = newWindow("Of Lands Configurator")
window.iconPath = "ol.png"

# containers
var main   = newLayoutContainer(Layout_Vertical)
var ct_map = newLayoutContainer(Layout_Horizontal)
var ct_mst = newLayoutContainer(Layout_Horizontal)
var ct_mex = newLayoutContainer(Layout_Horizontal)
var ct_fac = newLayoutContainer(Layout_Horizontal)
var ct_fav = newLayoutContainer(Layout_Vertical)
var ct_fin = newLayoutContainer(Layout_Horizontal)

# labels
var map_label = newLabel("Map used: ")
var map_size  = newLabel("") # size
var map_kd_ct = newLabel("") # kingdom count
var map_st_ct = newLabel("") # settlement count

# comboboxes
var cb_maps = newComboBox(maps)
var cb_facs = newComboBox(facToSeq(map_dt.kingdoms))

# checkboxes
var ch_curs = newCheckBox("Enable custom cursor")
var ch_road = newCheckBox("Enable roads (can slow down the game)")
var ch_gui  = newCheckBox("Enable additional GUI (buggy)")

# textareas
var ta_facs = newTextArea("")

# buttons
var bt_save = newButton("Save settings")
var bt_svrn = newButton("Save and start the game")

# registers
block registerMapLayer:
    ct_map.add(map_label)
    ct_map.add(cb_maps)
    ct_map.add(map_size)
    ct_map.add(map_kd_ct)
    ct_map.add(map_st_ct)
    # settings
    ct_map.frame  = newFrame("Map picker")
    ct_map.yAlign = YAlign_Center
block registerMapSettings:
    ct_mst.add(ch_curs)
    # settings
    ct_mst.frame  = newFrame("Game settings")
    ct_mst.yAlign = YAlign_Center
block registerMapExperimentalSettings:
    ct_mex.add(ch_road)
    ct_mex.add(ch_gui)
    # settings
    ct_mex.frame  = newFrame("Experimental settings")
    ct_mex.yAlign = YAlign_Center
block registerFactionLayer:
    ct_fac.add(ct_fav)
    ct_fav.add(cb_facs)
    ct_fac.add(ta_facs)
    # settings
    ct_fac.frame  = newFrame("Faction picker")
    ct_fac.yAlign = YAlign_Top
block registerFinalLayer:
    ct_fin.add(bt_save)
    ct_fin.add(bt_svrn)
    # settings
    ct_fin.xAlign = XAlign_Right
block registerLayers:
    main.add(ct_map)
    main.add(ct_fac)
    main.add(ct_mst)
    main.add(ct_mex)
    main.add(ct_fin)
window.add(main)

# initial values configuration
cb_maps.index    = find(maps, fmt"maps\{map_nm}")
cb_facs.index    = if parseInt(getSectionValue(cfg, "", "player")) <= len(cb_facs.options): parseInt(getSectionValue(cfg, "", "player")) - 1 else: 0
ch_gui.checked   = getSectionValue(cfg, "", "gui")    == "true"
ch_road.checked  = getSectionValue(cfg, "", "roads")  == "true"
ch_curs.checked  = getSectionValue(cfg, "", "cursor") == "true"
ta_facs.editable = false
ta_facs.height   = 100
ct_fav.height    = 100
setDescr(ta_facs, map_dt.kingdoms[cb_facs.index + 1])
if banners != nil: # checks if banner tileset exists
    setBanner(banners, cb_facs.index + 1, ban_ix)
if existsFile(fmt"_temp/banner_{ban_ix}_used.png"):
    ban_tab[ban_ix] = newImage()
    ban_tab[ban_ix].loadFromFile(fmt"_temp/banner_{ban_ix}_used.png")
setMapInfo(map_dt, map_size, map_kd_ct, map_st_ct)

proc saveConfig() =
    setSectionKey(cfg, "", "map",    multiReplace(cb_maps.value, [("maps/", ""), (r"maps\", "")]))
    setSectionKey(cfg, "", "player", $(cb_facs.index + 1))
    setSectionKey(cfg, "", "cursor", $ch_curs.checked)
    setSectionKey(cfg, "", "roads",  $ch_road.checked)
    setSectionKey(cfg, "", "gui",    $ch_gui.checked)
    writeConfig(cfg, "oflands.ini")

cb_maps.onChange = proc (event: ComboBoxChangeEvent) =
    map_dt = newMap(olm_file       = multiReplace(cb_maps.value, [("maps/", ""), (r"maps\", "")]),
                    player_kingdom = (nb: 0,
                                      nm: getSectionValue(cfg, "", "kingdom")),
                    )
    cb_facs.options = facToSeq(map_dt.kingdoms)
    banners = if existsFile(fmt"tilesets/{map_dt.data.tfacs}"): readImage(fmt"tilesets/{map_dt.data.tfacs}") else: nil
    setMapInfo(map_dt, map_size, map_kd_ct, map_st_ct)

cb_facs.onChange = proc (event: ComboBoxChangeEvent) =
    setDescr(ta_facs, map_dt.kingdoms[cb_facs.index + 1])
    if banners != nil: # checks if banner tileset exists
        ban_ix += 1
        setBanner(banners, cb_facs.index + 1, ban_ix)
        if existsFile(fmt"_temp/banner_{ban_ix}_used.png"):
            ban_tab[ban_ix] = newImage()
            ban_tab[ban_ix].loadFromFile(fmt"_temp/banner_{ban_ix}_used.png")
        else: ban_ix -= 1
        forceRedraw(ct_fav)

ct_fav.onDraw = proc (event: DrawEvent) =
    let canvas = event.control.canvas
    if ban_ix in ban_tab:
        canvas.drawImage(ban_tab[ban_ix], x=45,
                                          y=30)

bt_save.onClick = proc (event: ClickEvent) =
    saveConfig()
    quit()

bt_svrn.onClick = proc (event: ClickEvent) =
    saveConfig()
    discard execCmd("OfLands.exe")

# window.onCloseClick = proc(event: CloseClickEvent) =
#     # cleaning after finishing
#     if existsDir("_temp"):
#         removeDir("_temp")
#     window.dispose()

window.show()
app.run()