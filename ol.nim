import std/private/osdirs
import std/strformat
import std/strutils
import std/sequtils
import std/parsecfg
import std/options
import std/tables
import std/random
import questionable
import nico/backends/common
import nico
# OL imports
import core/render/colours
import core/roads
import core/time
import kingdom
import game
import gui
import map # only for `canExist`, remove if not needed

randomize()
###########################################
const GAME_NAME = "Of Lands"
const GAME_VER  = "0.1.0"
const AUTHOR    = "Toma400"
const LICENSE   = "All Rights Reserved (C) Tomasz Stępień 2025"
###########################################
let cfg = loadConfig("oflands.ini")
let grd = getSectionValue(cfg, "", "grid")   == "true"
let cur = getSectionValue(cfg, "", "cursor") == "true"
let roa = getSectionValue(cfg, "", "roads")  == "true" # TODO: EXPERIMENTAL

let player = parseInt(getSectionValue(cfg, "", "player"))
let map_fl = getSectionValue(cfg, "", "map")
let map_nm = replace(map_fl, ".olm", "")

var mvp = newMap(olm_file       = map_fl,
                 player_kingdom = (nb: player,
                                   nm: getSectionValue(cfg, "", "kingdom")),
                 )
var ses = newSession()

# TODO: MUSIC!!!
# let music  = if dirExists(fmt"music/{map_nm}"): toSeq(walkFiles(fmt"music/{map_nm}/*.ogg")) else: toSeq(walkFiles(fmt"music/*.ogg"))
# var mcount = 0
# for song in music:
#     if mcount < 61: # indexes 0..60
#         loadMusic(mcount, song)
#         mcount += 1
#     else: break

proc gameInit() =
    assetPath = basePath  # resets so folder structure can be fully configured
    registerPalettes(map = fmt"tilesets/{mvp.data.tterrain}",
                     loc = fmt"tilesets/{mvp.data.tlocs}",
                     fac = fmt"tilesets/{mvp.data.tfacs}",
                     sys = fmt"tilesets/{mvp.data.tsys}",
                     gui = "gui/gui.png"
    )
    loadSpritesheet(XMap.ord,  fmt"tilesets/{mvp.data.tterrain}",  TL,  TL) # 1 | map
    loadSpritesheet(XLoc.ord,  fmt"tilesets/{mvp.data.tlocs}",     TL,  TL) # 2 | locations
    loadSpritesheet(XFac.ord,  fmt"tilesets/{mvp.data.tfacs}",     TL,  TL) # 3 | factions
    loadSpritesheet(XGUI.ord,  "gui/gui.png",                      TL,  TL) # 4 | gui
    loadSpritesheet(XSys.ord,  fmt"tilesets/{mvp.data.tsys}",      TL,  TL) # 5 | system
    loadSpritesheet(XGrid.ord, "gui/grid.png",                    960, 960) # 6 | grid
    loadFont(1, "gui/font.png"); setFont(1)      # font setup
    # initialises game (may need to be changed when game saves are made, so it makes you fail the game when this is achieved post-init stage)
    if mvp.kingdoms[player].settlems.len == 0 and mvp.kingdoms[player].entities.len == 0: # todo: replace `locations` with `settlements` ig
        ses.mode = INIT
    #updateRoads(addr mvp)
    # var settlement_count: int
    # for _, k in mvp.kingdoms.pairs():
    #     for i in k.settlems:
    #         settlement_count += 1
    # echo settlement_count

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
        elif ses.mode == INIT:
            if addEntity(mvp.data.mapping[getCellCoords(mvp, mouse())], mvp.kingdoms[player], SETTLER):
                ses.mode = EXPLORE
    if mousebtnpr(1):
        discard addSettlement(mvp.data.mapping[getCellCoords(mvp, mouse())], mvp.kingdoms[player])
    if mousebtnpr(2):
        if ses.bdb == -1:
            let tile = mvp.data.mapping[getCellCoords(mvp, mouse())]
            if isSome(tile.location):
                ses.bdb = (!tile.location).index
        else:
            let loc_pf = mvp.data.ldefs[ses.bdb]
            discard addLocation(mvp.data.mapping[getCellCoords(mvp, mouse())], mvp.kingdoms[player], loc_pf, ses.bdb)
            ses.bdb = -1
    if roa:
        updateRoads(mvp)
    # TODO: MUSIC!!
    # if mcount > 0: # if music is available
    #     if getMusic(0) == -1: # play new music if nothing is playing
    #         music(0, rand(0..mcount), loop=0)

proc gameDraw() =
    cls()
    drawMap(mvp)
    drawGUI(mvp, ses, cur, player)
    if grd: # checks if grid setting is set
        drawGrid()

nico.init(org=AUTHOR, app=GAME_NAME)
nico.createWindow(GAME_NAME, W, H, 1, false)
setWindowIcon("ol.ico")
nico.run(gameInit, gameUpdate, gameDraw)