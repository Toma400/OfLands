import std/strformat
import std/strutils
import std/parsecfg
import std/options
import std/tables
import questionable
import nico/backends/common
import nico
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

var mvp = newMap(olm_file      = getSectionValue(cfg, "", "map"),
                 kingdoms      = initKingdoms(newKingdom(name   =          getSectionValue(cfg, "", "kingdom"),
                                                         number = parseInt(getSectionValue(cfg, "", "player")))),
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
                     gui = "gui/gui.png"
    )
    loadSpritesheet(XMap.ord,  fmt"tilesets/{mvp.data.tterrain}",  TL,  TL) # 1 | map
    loadSpritesheet(XLoc.ord,  fmt"tilesets/{mvp.data.tlocs}",     TL,  TL) # 2 | locations
    loadSpritesheet(XGUI.ord,  "gui/gui.png",                      TL,  TL) # 3 | gui
    loadSpritesheet(XGrid.ord, "gui/grid.png",                    960, 960) # 4 | grid
    loadFont(1, "gui/font.png"); setFont(1)      # font setup

proc gameUpdate(dt: float32) =
    if btn(pcLeft):  moveMap(mvp, (-1,  0), dt)
    if btn(pcRight): moveMap(mvp, (1,   0), dt)
    if btn(pcUp):    moveMap(mvp, (0,  -1), dt)
    if btn(pcDown):  moveMap(mvp, (0,   1), dt)
    if btnpr(pcA):
        ses.focus = (-1, -1) # resets focus
        if ses.mode != ROUTE: ses.mode = ROUTE
        else:                 ses.mode = EXPLORE
    if mousebtnpr(0):
        if ses.mode == EXPLORE:
            if ses.focus != getCellCoords(mvp, mouse()):
                ses.focus = getCellCoords(mvp, mouse())
            else: ses.focus = (-1, -1)
        if ses.mode == ROUTE: # TODO: temporary, just for showcase
            if mvp.data.mapping[getCellCoords(mvp, mouse())].location.isNone:
                if canExist(mvp.data.mapping[getCellCoords(mvp, mouse())], newLocation(mvp.data.ldefs, 0)): # safeguard to not build on water
                    mvp.data.mapping[getCellCoords(mvp, mouse())].location = newLocation(mvp.data.ldefs, 0).some # should be replaced with dedicated `buildLocation`
            elif mvp.data.mapping[getCellCoords(mvp, mouse())].location.isSome:
                if (!mvp.data.mapping[getCellCoords(mvp, mouse())].location).index == 0:
                    mvp.data.mapping[getCellCoords(mvp, mouse())].location = newLocation(mvp.data.ldefs, 1).some
    passTime(mvp, ses)

proc gameDraw() =
    cls()
    drawMap(mvp)
    drawGUI(mvp, ses)
    if getSectionValue(cfg, "", "grid") == "true":
        drawGrid()

nico.init(org="Toma400", app=GAME_NAME)
nico.createWindow(GAME_NAME, W, H, 1, false)
nico.run(gameInit, gameUpdate, gameDraw)