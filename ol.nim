import std/parsecfg
import nico
import game
import gui

###########################################
const GAME_NAME = "Of Lands"
const GAME_VER  = "0.1.0"
###########################################
let cfg = loadConfig("oflands.ini")

var map = newMap(getSectionValue(cfg, "", "map"))
var ses = newSession()

proc gameInit() =
    assetPath = basePath  # resets so folder structure can be fully configured
    block palettePreload: # initial palette start
      setPalette(getPalette(map)) # map
      setPalette(getGUIPalette()) # GUI
    loadSpritesheet(2, "gui/gui.png",   32,  32) # gui
    loadSpritesheet(3, "gui/grid.png", 960, 960) # grid
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