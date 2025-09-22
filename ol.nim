import std/strformat
import nico
import game

const GAME_NAME  = "Of Lands"
const MAP_PICKED = "default.olm"

let map = newMap(MAP_PICKED, map_index=1)

proc gameInit() =
    assetPath = basePath # resets so folder structure can be fully configured
    setPalette(loadPaletteFromImage(fmt"tilesets/example_palette.png"))
    loadSpritesheet(3, "gui/grid.png", 960, 960) # grid setup

proc gameUpdate(dt: float32) =
    discard

proc gameDraw() =
    cls()
    drawMap(map)

nico.init(org="Toma400", app=GAME_NAME)
nico.createWindow(GAME_NAME, 960, 960, 1, false)
nico.run(gameInit, gameUpdate, gameDraw)