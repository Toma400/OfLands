import std/strformat
import std/sequtils
import std/strutils
import std/parsecfg
import std/osproc
import std/tables
import parsetoml
import nigui
import os

import kingdom
import game

proc facToSeq (ot: OrderedTable[int, Kingdom]): seq[string] =
    for i, k in ot.pairs():
        result.add(k.name)

let maps     = toSeq(walkFiles("maps/*.olm"))

# data
var cfg    = loadConfig("oflands.ini")
let map_nm = getSectionValue(cfg, "", "map")
var map_dt = newMap(olm_file       = map_nm,
                    player_kingdom = (nb: 0,
                                      nm: getSectionValue(cfg, "", "kingdom")),
                    )

# app run
app.init()
var window = newWindow("Of Lands Configurator")

# containers
var main   = newLayoutContainer(Layout_Vertical)
var ct_map = newLayoutContainer(Layout_Horizontal)
var ct_mst = newLayoutContainer(Layout_Horizontal)
var ct_fac = newLayoutContainer(Layout_Horizontal)
var ct_fav = newLayoutContainer(Layout_Vertical)
var ct_fin = newLayoutContainer(Layout_Horizontal)

# labels
var map_label = newLabel("Map used: ")

# comboboxes
var cb_maps = newComboBox(maps)
var cb_facs = newComboBox(facToSeq(map_dt.kingdoms))

# checkboxes
var ch_curs = newCheckBox("Enable custom cursor")
var ch_road = newCheckBox("Enable roads (experimental: performance heavy)")

# textboxes
var tb_facs = newTextBox("")

# images
# var img_fac = newImage() TODO: `canvas.drawImage()` draws images on layoutcontainers, meaning this is only to register image as a thing

# buttons
var bt_save = newButton("Save settings")
var bt_svrn = newButton("Save and start the game")

# registers
block registerMapLayer:
    ct_map.add(map_label)
    ct_map.add(cb_maps)
    # settings
    ct_map.frame  = newFrame("Map picker")
    ct_map.yAlign = YAlign_Center
block registerMapSettings:
    ct_mst.add(ch_curs)
    ct_mst.add(ch_road)
    # settings
    ct_mst.frame  = newFrame("Map settings")
    ct_mst.yAlign = YAlign_Center
block registerFactionLayer:
    ct_fac.add(ct_fav)
    ct_fav.add(cb_facs)
    # todo: ct_fav.add(img_fac) // make it a container
    ct_fac.add(tb_facs)
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
    main.add(ct_fin)
window.add(main)

# initial values configuration
cb_maps.index    = find(maps, fmt"maps\{map_nm}")
ch_road.checked  = getSectionValue(cfg, "", "roads")  == "true"
ch_curs.checked  = getSectionValue(cfg, "", "cursor") == "true"
tb_facs.editable = false
tb_facs.height   = 100

proc saveConfig() =
    setSectionKey(cfg, "", "map",    multiReplace(cb_maps.value, [("maps/", ""), (r"maps\", "")]))
    setSectionKey(cfg, "", "player", $(cb_facs.index + 1))
    setSectionKey(cfg, "", "cursor", $ch_curs.checked)
    setSectionKey(cfg, "", "roads",  $ch_road.checked)
    writeConfig(cfg, "oflands.ini")

cb_maps.onChange = proc (event: ComboBoxChangeEvent) =
    map_dt = newMap(olm_file       = multiReplace(cb_maps.value, [("maps/", ""), (r"maps\", "")]),
                    player_kingdom = (nb: 0,
                                      nm: getSectionValue(cfg, "", "kingdom")),
                    )
    cb_facs.options = facToSeq(map_dt.kingdoms)

cb_facs.onChange = proc (event: ComboBoxChangeEvent) =
    tb_facs.text = map_dt.kingdoms[cb_facs.index + 1].descr

bt_save.onClick = proc (event: ClickEvent) =
    saveConfig()

bt_svrn.onClick = proc (event: ClickEvent) =
    saveConfig()
    discard execCmd("OfLands.exe")

window.show()
app.run()