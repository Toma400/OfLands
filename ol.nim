import std/strformat
import std/strutils
import std/options
import std/tables
import std/random
import questionable
import nico/backends/common
import nico/gui
import nico
# OL imports
import core/render/colours
import core/gui/nicogui
import core/settlement # temp for checking when clicking
import core/location   # as above, but is it temp tho??
import core/gui/main
import core/logging
import core/system
import core/roads
import core/time
import kingdom
import game
import map # only for `canExist`, remove if not needed

randomize()
#################################################################
# Config values (later = editable, reachable via `core/system`)
#----------------------------------------------------------------
let grd = getSectionValue(cfg, "", "grid")   == "true"
let cur = getSectionValue(cfg, "", "cursor") == "true"
let roa = getSectionValue(cfg, "", "roads")  == "true" # TODO: EXPERIMENTAL

let player = parseInt(getSectionValue(cfg, "", "player"))
let map_fl = getSectionValue(cfg, "", "map")
let map_nm = replace(map_fl, ".olm", "")

var mvp : Map
var ses : Session
try: # put into try/except so that errors can be caught in logs
    mvp = newMap(olm_file       = map_fl,
                   player_kingdom = (nb: player,
                                     nm: getSectionValue(cfg, "", "kingdom")),
                   )
    ses = newSession()
except Exception as exc:
    dumpLog(log, exc.msg); quit() # continues with crash

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
    log |: "Registering colour palettes..."
    registerPalettes(cref = col_referrer,
                     map = fmt"tilesets/{mvp.data.tterrain}",
                     loc = fmt"tilesets/{mvp.data.tlocs}",
                     fac = fmt"tilesets/{mvp.data.tfacs}",
                     res = fmt"tilesets/{mvp.data.tres}",
                     sys = fmt"tilesets/{mvp.data.tsys}",
                     gui = "gui/gui.png"
    )
    log |> "Loading spreadsheets...":
        loadSpritesheet(XMap.ord,  fmt"tilesets/{mvp.data.tterrain}",  TL,  TL) # 1 | map
        loadSpritesheet(XLoc.ord,  fmt"tilesets/{mvp.data.tlocs}",     TL,  TL) # 2 | locations
        loadSpritesheet(XFac.ord,  fmt"tilesets/{mvp.data.tfacs}",     TL,  TL) # 3 | factions
        loadSpritesheet(XRes.ord,  fmt"tilesets/{mvp.data.tres}",      TL,  TL) # 4 | factions
        loadSpritesheet(XGUI.ord,  "gui/gui.png",                      TL,  TL) # 5 | gui
        loadSpritesheet(XSys.ord,  fmt"tilesets/{mvp.data.tsys}",      TL,  TL) # 6 | system
        loadSpritesheet(XGrid.ord, "gui/grid.png",                    960, 960) # 7 | grid
    log |: "Loading fonts..."
    loadFont(1, "gui/font.png"); setFont(1)      # font setup
    log |: "All initial resources loaded successfully"
    # initialises game (may need to be changed when game saves are made, so it makes you fail the game when this is achieved post-init stage)
    if mvp.kingdoms[player].settlems.len == 0 and mvp.kingdoms[player].entities.len == 0: # todo: replace `locations` with `settlements` ig
        ses.gmode = INIT
    log |: "Initialising GUI theme..."
    initGUITheme()
    #updateRoads(addr mvp)
    # var settlement_count: int
    # for _, k in mvp.kingdoms.pairs():
    #     for i in k.settlems:
    #         settlement_count += 1
    # echo settlement_count

proc turn() =
    passTime(mvp, ses, TURN_HOUR) # progresses time with hours set in `time.nim`
    if getDayPhase(mvp) == DAY: # production time
        productionPhase(mvp)

proc gameGUI() =
    resourceGUI(mvp, ses, player)
    turnButton(turn)
    facmodeButton(ses)

proc gameUpdate(dt: float32) =
    if btn(pcLeft):  moveMap(mvp, (-1,  0), dt)
    if btn(pcRight): moveMap(mvp, (1,   0), dt)
    if btn(pcUp):    moveMap(mvp, (0,  -1), dt)
    if btn(pcDown):  moveMap(mvp, (0,   1), dt)
    if btnpr(pcA): # space/Z/Y
        turn() # todo: should keep us from doing this action again before all turn things process on screen/data
    if mousebtnpr(0): # left click
        if ses.gmode == EXPLORE:
            # avoid resetting focus when clicking on menu???
            if isPxWithinMap(mvp, mouse()):
              if ses.focus != getCellCoords(mvp, mouse()):
                  ses.focus = getCellCoords(mvp, mouse())

                  ses.fobj = (-1, Location.none, SettlementTile.none) # defaults to reset (overwrites if not)
                  if isPxWithinMap(mvp, mouse()):
                    let tl = mvp.data.mapping[getCellCoords(mvp, mouse())]
                    if hasObject(tl):
                        ses.fobj = (0, tl.location, tl.settile) # 0 = pending
                        if tl.settile.isSome:
                            ses.fobj.state = 2
                        elif tl.location.isSome:
                            ses.fobj.state = 1
              else:
                  ses.focus = (-1, -1)
                  ses.fobj  = (-1, Location.none, SettlementTile.none) # defaults to reset (overwrites if not)

        elif ses.gmode == INIT:
            if addEntity(mvp.data.mapping[getCellCoords(mvp, mouse())], mvp.kingdoms[player], SETTLER):
                ses.gmode = EXPLORE
    if mousebtnpr(1): # middle click
        discard addSettlement(mvp.data.mapping[getCellCoords(mvp, mouse())], mvp.kingdoms[player])
    if mousebtnpr(2): # right click
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
    G.update(gameGUI, dt)

proc gameDraw() =
    cls()
    drawMap(mvp, ses)
    drawGUI(mvp, ses, gameGUI, cur, player)
    if grd: # checks if grid setting is set
        drawGrid()

nico.init(org=AUTHOR, app=GAME_NAME)
nico.createWindow(GAME_NAME, W, H, 1, false)
setWindowIcon("ol.ico")
try:
  nico.run(gameInit, gameUpdate, gameDraw)
except Exception as exc:
  dumpLog(log, exc.msg); quit() # continues with crash
dumpLog(log)