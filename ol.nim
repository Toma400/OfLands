import std/strformat
import std/strutils
import std/parsecfg
import std/options
import std/tables
import questionable
import nico/backends/common
import nico
# OL imports
import kingdom
import render
import time
import game
import gui
import map # only for `canExist`, remove if not needed

###########################################
const GAME_NAME = "Of Lands"
const GAME_VER  = "0.1.0"
const AUTHOR    = "Toma400"
const LICENSE   = "All Rights Reserved (C) Tomasz Stępień 2025"
###########################################
let cfg = loadConfig("oflands.ini")
let grd = getSectionValue(cfg, "", "grid")   == "true"
let cur = getSectionValue(cfg, "", "cursor") == "true"

let player = parseInt(getSectionValue(cfg, "", "player"))

var mvp = newMap(olm_file      = getSectionValue(cfg, "", "map"),
                 kingdoms      = initKingdoms(newKingdom(name   =          getSectionValue(cfg, "", "kingdom"),
                                                         number = parseInt(getSectionValue(cfg, "", "player")))), # done explicitly because `player` may change
                 starting_date = (
                              parseInt(getSectionValue(cfg, "", "year")),
                              parseInt(getSectionValue(cfg, "", "month")),
                              parseInt(getSectionValue(cfg, "", "day"))
                 ))
var ses = newSession()

proc gameInit() =
    assetPath = basePath  # resets so folder structure can be fully configured
    registerPalettes(map = fmt"tilesets/{mvp.data.tterrain}",
                     loc = fmt"tilesets/{mvp.data.tlocs}",
                     sys = fmt"tilesets/{mvp.data.tsys}",
                     gui = "gui/gui.png"
    )
    loadSpritesheet(XMap.ord,  fmt"tilesets/{mvp.data.tterrain}",  TL,  TL) # 1 | map
    loadSpritesheet(XLoc.ord,  fmt"tilesets/{mvp.data.tlocs}",     TL,  TL) # 2 | locations
    loadSpritesheet(XGUI.ord,  "gui/gui.png",                      TL,  TL) # 3 | gui
    loadSpritesheet(XSys.ord,  fmt"tilesets/{mvp.data.tsys}",      TL,  TL) # 4 | system
    loadSpritesheet(XGrid.ord, "gui/grid.png",                    960, 960) # 5 | grid
    loadFont(1, "gui/font.png"); setFont(1)      # font setup
    # initialises game (may need to be changed when game saves are made, so it makes you fail the game when this is achieved post-init stage)
    if mvp.kingdoms[player].locations.len == 0 and mvp.kingdoms[player].entities.len == 0: # todo: replace `locations` with `settlements` ig
        ses.mode = INIT

proc turn() =
    passTime(mvp, ses, 12) # progresses hours 12 hours

proc gameUpdate(dt: float32) =
    if btn(pcLeft):  moveMap(mvp, (-1,  0), dt)
    if btn(pcRight): moveMap(mvp, (1,   0), dt)
    if btn(pcUp):    moveMap(mvp, (0,  -1), dt)
    if btn(pcDown):  moveMap(mvp, (0,   1), dt)
    if btnpr(pcA): # space/Z/Y
        turn() # todo: should keep us from doing this action again before all turn things process on screen/data
    if mousebtnpr(0):
        if ses.mode == EXPLORE:
            if ses.focus != getCellCoords(mvp, mouse()):
                ses.focus = getCellCoords(mvp, mouse())
            else: ses.focus = (-1, -1)
        elif ses.mode == ROUTE: # TODO: temporary, just for showcase
            if mvp.data.mapping[getCellCoords(mvp, mouse())].location.isNone:
                if canExist(mvp.data.mapping[getCellCoords(mvp, mouse())], newLocation(mvp.data.ldefs, 0)): # safeguard to not build on water
                    mvp.data.mapping[getCellCoords(mvp, mouse())].location = newLocation(mvp.data.ldefs, 0).some # should be replaced with dedicated `buildLocation`
            elif mvp.data.mapping[getCellCoords(mvp, mouse())].location.isSome:
                if (!mvp.data.mapping[getCellCoords(mvp, mouse())].location).index == 0:
                    mvp.data.mapping[getCellCoords(mvp, mouse())].location = newLocation(mvp.data.ldefs, 1).some
        elif ses.mode == INIT:
            if addEntity(mvp.data.mapping[getCellCoords(mvp, mouse())], mvp.kingdoms[player], SETTLER):
                ses.mode = EXPLORE

proc gameDraw() =
    cls()
    drawMap(mvp)
    drawGUI(mvp, ses, cur)
    if grd: # checks if grid setting is set
        drawGrid()

nico.init(org=AUTHOR, app=GAME_NAME)
nico.createWindow(GAME_NAME, W, H, 1, false)
nico.run(gameInit, gameUpdate, gameDraw)