import std/strformat
import std/parsecfg
import std/tables
import nico/backends/common
import nico
import kingdom
import render
import game
import gui

###########################################
const GAME_NAME = "Of Lands"
const GAME_VER  = "0.1.0"
###########################################
let cfg = loadConfig("oflands.ini")

var map = newMap(getSectionValue(cfg, "", "map"), initKingdoms(newKingdom(getSectionValue(cfg, "", "kingdom"))))
var ses = newSession()

proc gameInit() =
    assetPath = basePath  # resets so folder structure can be fully configured
    block palettePreload: # initial palette start
      setMapPalette(fmt"tilesets/{map.data.tileset}"); # index: 1
      setGUIPalette("gui/gui.png")                     # index: 2
      setPalette(getMapPalette()) # 1: map
      setPalette(getGUIPalette()) # 2: GUI
    loadSpritesheet(XMap.ord,  fmt"tilesets/{map.data.tileset}",  TL,  TL) # 1 | map
    loadSpritesheet(XGUI.ord,  "gui/gui.png",                     TL,  TL) # 2 | gui
    loadSpritesheet(XGrid.ord, "gui/grid.png",                   960, 960) # 3 | grid
    loadFont(1, "gui/font.png"); setFont(1)      # font setup

proc gameUpdate(dt: float32) =
    if btn(pcLeft):  moveMap(map, (-1,  0))
    if btn(pcRight): moveMap(map, (1,   0))
    if btn(pcUp):    moveMap(map, (0,  -1))
    if btn(pcDown):  moveMap(map, (0,   1))
    if btn(pcA):
        if ses.mode != ROUTE: ses.mode = ROUTE
        else:                 ses.mode = EXPLORE
    if mousebtnpr(0):
        if ses.mode == EXPLORE:
            if ses.focus != getCellCoords(map, mouse()):
                ses.focus = getCellCoords(map, mouse())
            else: ses.focus = (-1, -1)

proc gameDraw() =
    cls()
    drawMap(map)
    drawGUI(map, ses)
    if getSectionValue(cfg, "", "grid") == "true":
        drawGrid()

nico.init(org="Toma400", app=GAME_NAME)
nico.createWindow(GAME_NAME, W, H, 1, false)
nico.run(gameInit, gameUpdate, gameDraw)