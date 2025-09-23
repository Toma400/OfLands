import std/strformat
import nico
import game

###########################################
const GAME_NAME = "Of Lands"
const GAME_VER  = "0.1.0"
###########################################
const MAP_PICKED = "default2.olm"

var map = newMap(MAP_PICKED)

proc gameInit() =
    assetPath = basePath # resets so folder structure can be fully configured
    setPalette(loadPaletteFromImage(fmt"tilesets/example_palette.png"))
    loadSpritesheet(3, "gui/grid.png", 960, 960) # grid setup

proc gameUpdate(dt: float32) =
    if btn(pcLeft):  moveMap(map, (-1,  0))
    if btn(pcRight): moveMap(map, (1,   0))
    if btn(pcUp):    moveMap(map, (0,  -1))
    if btn(pcDown):  moveMap(map, (0,   1))

proc gameDraw() =
    cls()
    drawMap(map)

nico.init(org="Toma400", app=GAME_NAME)
nico.createWindow(GAME_NAME, 960, 960, 1, false)
nico.run(gameInit, gameUpdate, gameDraw)