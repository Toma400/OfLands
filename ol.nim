import std/strformat
import std/strutils
import std/parsecfg
import nico/backends/common
import nico
import kingdom
import render
import time
import game
import gui

###########################################
const GAME_NAME = "Of Lands"
const GAME_VER  = "0.1.0"
###########################################
let cfg = loadConfig("oflands.ini")

var map = newMap(olm_file      = getSectionValue(cfg, "", "map"),
                 kingdoms      = initKingdoms(newKingdom(name   = getSectionValue(cfg, "", "kingdom"),
                                                         number = 1)),
                 starting_date = (
                              parseInt(getSectionValue(cfg, "", "year")),
                              parseInt(getSectionValue(cfg, "", "month")),
                              parseInt(getSectionValue(cfg, "", "day"))
                 ))
var ses = newSession()

proc gameInit() =
    assetPath = basePath  # resets so folder structure can be fully configured
    registerPalettes(map = fmt"tilesets/{map.data.tterrain}",
                     loc = fmt"tilesets/{map.data.tlocs}",
                     gui = "gui/gui.png"
    )
    loadSpritesheet(XMap.ord,  fmt"tilesets/{map.data.tterrain}",  TL,  TL) # 1 | map
    loadSpritesheet(XLoc.ord,  fmt"tilesets/{map.data.tlocs}",     TL,  TL) # 2 | locations
    loadSpritesheet(XGUI.ord,  "gui/gui.png",                      TL,  TL) # 3 | gui
    loadSpritesheet(XGrid.ord, "gui/grid.png",                    960, 960) # 4 | grid
    loadFont(1, "gui/font.png"); setFont(1)      # font setup

proc gameUpdate(dt: float32) =
    if btn(pcLeft):  moveMap(map, (-1,  0), dt)
    if btn(pcRight): moveMap(map, (1,   0), dt)
    if btn(pcUp):    moveMap(map, (0,  -1), dt)
    if btn(pcDown):  moveMap(map, (0,   1), dt)
    if btnpr(pcA):
        ses.focus = (-1, -1) # resets focus
        if ses.mode != ROUTE: ses.mode = ROUTE
        else:                 ses.mode = EXPLORE
    if mousebtnpr(0):
        if ses.mode == EXPLORE:
            if ses.focus != getCellCoords(map, mouse()):
                ses.focus = getCellCoords(map, mouse())
            else: ses.focus = (-1, -1)
    passTime(map, ses)

proc gameDraw() =
    cls()
    drawMap(map)
    drawGUI(map, ses)
    if getSectionValue(cfg, "", "grid") == "true":
        drawGrid()

nico.init(org="Toma400", app=GAME_NAME)
nico.createWindow(GAME_NAME, W, H, 1, false)
nico.run(gameInit, gameUpdate, gameDraw)