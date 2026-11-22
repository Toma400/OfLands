import std/strformat
import std/sequtils
import std/tables
# other imports
import questionable
import nico/gui
import nico
# OL imports
import ../render/colours
import ../../game
import ../settlement
import main

const
  MW = MV*TL  # map width
  SW = W - MW # sidebar width
type
  GUIIcons = enum # helper that directs to `gui.png` indexes for particular icons
    # decor
    dcStart  = 12
    dcMid    = 13
    dcEnd    = 14
    dcSingle = 15
    # map modes
    mmTerrain  = 16
    mmFactions = 17
    # production
    pdEnabled  = 18
    pdDisabled = 19
  tAlign = enum # text alignment
    CENTERED
    LEFT
    RIGHT

var
  # buttons
  bTURN_padX = TL*2 # padding X
  # -- start coordinates
  bTURN_stX : Pint = MW + bTURN_padX
  bTURN_stY : Pint = H - TL*4
  bRES_stX  : Pint = bTURN_stX + 120
  bRES_stY  : Pint = bTURN_stY - 60 - 310 + 6 # () is bMM_stY
  # -- size
  bTURN_szX : Pint = W - MW - 2*(bTURN_padX) # window width - map area - padding from both sides
  bTURN_szY : Pint = 50
  # -- options
  bTURN_on  : bool = true # todo: does it need to be `bTURN` specifically? will it be used for anything really?

  # o tempora(ry) o mores - map modes
  bMM_stY     = bTURN_stY - 60                   # 60 pxs above `turnButton`
  bMM_count   : Pint = 2                         # todo: count of buttons
  bMM_space   : Pint = bMM_count                 # spacing between buttons (1 pixel more for each, giving them space for outline)
  bMM_size    : Pint = TL                        # x/y are squares here
  bMM_fwidth  = bMM_size * bMM_count + bMM_space # container width (buttons + TL spacing)
  bMM_fheight = bMM_size                         # container height (button height)
  bMMFac_stX  = bTURN_stX + bMM_size + bMM_space # second button X coords (starting X, first button, spacing)

proc WORKAROUND_TEXT (text: string, x, y: int | Pint, size : int = 3, ta : tAlign = CENTERED) =
    # proc that is meant to be replaced with Nico rework on GUI blitting - things like buttons should be able to have text size adjusted
    # but until then, we will just blit text on top of empty GUI objects and call it a day
    useColour(CTFLT) # guess what, we use NicoGUI's colours even
    case ta:
      of LEFT     : print(text,  x = x + 100, y = y + 15, size)
      of CENTERED : printc(text, x = x + 100, y = y + 15, size)
      of RIGHT    : printr(text, x = x + 100, y = y + 15, size)

proc turnButton* (proced: proc) =
    if G.beginWindow("", bTURN_stX, bTURN_stY, bTURN_szX, bTURN_szY, bTURN_on):
        if G.button("", bTURN_stX, bTURN_stY, bTURN_szX, bTURN_szY): # End Turn
            proced()
        G.endArea()
    WORKAROUND_TEXT("End Turn", bTURN_stX, bTURN_stY)

proc facmodeButton* (ses: var Session) =
    if G.beginWindow("", bTURN_stX, bMM_stY, bMM_fwidth, bMM_fheight, bTURN_on):
        if G.button("", bTURN_stX, bMM_stY, bMM_size, bMM_size):
            ses.mmode = TERRAIN
        if G.button("", bMMFac_stX, bMM_stY, bMM_size, bMM_size):
            ses.mmode = FACTIONS
        G.endArea()
    useSpritesheet(XGUI)
    sprs(mmTerrain.ord,  x = bTURN_stX,  y = bMM_stY, dw = 1, dh = 1)
    sprs(mmFactions.ord, x = bMMFac_stX, y = bMM_stY, dw = 1, dh = 1)
    WORKAROUND_TEXT("Map Modes", bTURN_stX + 30, bMM_stY - 5)

proc resourceCard (m: Map, rs_ix: int, rs_cnt: int, spc: var int, prod_rs: ptr Table[int, bool]) =
    # used for single resource card, since their entries will repeat
    # rs_ix  : int | index of resource
    # rs_cnt : int | resource count / amount in storage
    # spc    : int | Y spacing      / Y position on GUI
    # prod_rs      | production sheet
    let rs = m.data.rdefs[rs_ix] # Resource object

    useSpritesheet(XRes)
    sprs(rs.index, x = bTURN_stX - 30, y = bTURN_stY - 310 + spc + 6, dw = 1, dh = 1) # +1 bc asset is 32 so it centers it (34-32 = 2, 1 up, 1 down)
    useSpritesheet(XGUI) # comeback?
    WORKAROUND_TEXT(fmt"{rs.name}", bTURN_stX - 85, bTURN_stY - 310 + spc, ta=LEFT)
    WORKAROUND_TEXT(fmt"{rs_cnt}",  bTURN_stX + 90, bTURN_stY - 310 + spc)
    # production enabling
    if rs_ix in prod_rs[]:
        var bY : Pint = bTURN_stY - 310 + spc + 6  # dumb var needed for Nico, including spacing
        let ps = prod_rs[][rs_ix]                    # production state (enabled/disabled)
        let ac = if ps: pdEnabled else: pdDisabled # bool indicator
        # sprs(dcSingle.ord, x = bTURN_stX + 120, y = bTURN_stY - 310 + spc + 6, dw = 1, dh = 1)
        if G.beginWindow("", bRES_stX, bY, bMM_size, bMM_size, bTURN_on):
            if G.button("", bRES_stX, bY, bMM_size, bMM_size):
                prod_rs[][rs_ix] = not prod_rs[][rs_ix]
            G.endArea()
        sprs(ac.ord, x = bRES_stX, y = bY, dw = 1, dh = 1)
    spc += 34 # separating resources vertically

proc resourceGUI* (m: Map, ses: Session, player: int) =
    # player : int | player faction number
    if ses.fobj.state != -1: # actual tile with object is selected
    # EVENTUALLY the above should also bounce against ownership! or entity overlapping the tile
    # so that you don't know resources of locs/settlements of others
    # can be helpful for debbuging rn though
        var owner   : int
        var rs_cap  : int
        var rs_wgt  : int
        var rs_lst  : OrderedTable[int, int]  # list of resources
        var spc     = 0                       # visual spacing (temp before proper listbox is made)
        var prod_rs : ptr Table[int, bool]    # production sheet
        if ses.fobj.state == 1: # location
            rs_cap  = (!ses.fobj.loc).res_cap
            rs_wgt  = (!ses.fobj.loc).res_wgt
            rs_lst  = (!ses.fobj.loc).res
            owner   = (!ses.fobj.loc).owner
            prod_rs = addr (!ses.fobj.loc).prod_rs
        elif ses.fobj.state == 2: # settlement
            rs_cap  = storageCap((!ses.fobj.stile))
            rs_wgt  = (!ses.fobj.stile).res_wgt
            rs_lst  = (!ses.fobj.stile).res
            owner   = (!ses.fobj.stile).settlem.owner
            prod_rs = addr (!ses.fobj.stile).prod_rs # empty, temporarily w/o systems so that there's no nullpointers

        if owner == player: # gates viewing resources by ownership by player | TODO: should also (partially) show if entity stands on it [0.1.4 todo]
            WORKAROUND_TEXT("Storage", bTURN_stX, bTURN_stY - 370, 4)
            WORKAROUND_TEXT(fmt"{rs_wgt} / {rs_cap}", bTURN_stX, bTURN_stY - 340)
            if len(rs_lst) > 0 or len(prod_rs[]) > 0:
              WORKAROUND_TEXT("----------------------------------", bTURN_stX, bTURN_stY - 325, 2)
            # this list can go forever, so eventually listbox must descope to have particular [range..range]
            # ...and ranges be moved by buttons (range could probably be held by the same tuple? and be resetted each time loc/stile swaps? in ol.nim)
            for rs_ix, _ in prod_rs[]: # iterating over produced resources first (including not stored ones)
                let rs_cnt = if rs_ix in rs_lst: rs_lst[rs_ix] else: 0
                resourceCard(m, rs_ix, rs_cnt, spc, prod_rs)
            for rs_ix, rs_cnt in rs_lst:
                if rs_ix notin prod_rs[]: # checks if it didn't show up already in prod_rs cycle
                    resourceCard(m, rs_ix, rs_cnt, spc, prod_rs)
            if len(rs_lst) > 0 or len(prod_rs[]) > 0:
              WORKAROUND_TEXT("----------------------------------", bTURN_stX, bTURN_stY - 325 + spc, 2)

proc initGUITheme* () =
    # TODO: Important note, `Dark` mode has more fields that could be used for `Light` one - e.g.
    # "fill_disabled" etc. which feel very important on longer run
    # maybe those could be used through modes (`gDefault`) but it could be useful to use option to disable
    # explicitly, as it's more natural to work through this
    # OBVIOUSLY our workaround text would need to follow disable status of gui element, so
    # we should make GUI work out of the box from Nico, OR expand our workaround to follow
    colorSetLight[gDefault].modalOutline           = 0
    colorSetLight[gDefault].windowTitleFillFocused = 12
    colorSetLight[gDefault].windowTitleTextFocused = 7
    colorSetLight[gDefault].windowTitleFill        = col_referrer[CMAIN] # todo? no idea what is it? | 1
    colorSetLight[gDefault].windowTitleText        = 6

    colorSetLight[gDefault].hoverOutline = col_referrer[CHVOL]

    colorSetLight[gDefault].textFlat     = col_referrer[CTFLT]
    colorSetLight[gDefault].textInset    = col_referrer[CTINS]
    colorSetLight[gDefault].textOutset   = col_referrer[CTOTS]
    colorSetLight[gDefault].textDisabled = col_referrer[CTDIS]

    colorSetLight[gDefault].outlineFlat       = col_referrer[CMAIN] # todo? no idea what is it? | 5
    colorSetLight[gDefault].outlineInset      = col_referrer[CMAIN] # todo? no idea what is it? | 5
    colorSetLight[gDefault].outlineInsetLit   = col_referrer[CMAIN] # todo? no idea what is it? | 7
    colorSetLight[gDefault].outlineInsetDark  = col_referrer[CMAIN] # todo? no idea what is it? | 1
    colorSetLight[gDefault].outlineOutset     = col_referrer[COUTL] # sides of the button
    colorSetLight[gDefault].outlineOutsetLit  = col_referrer[COUTL] # upper part of button
    colorSetLight[gDefault].outlineOutsetDark = col_referrer[COUTL] # bottom part of button

    colorSetLight[gDefault].fillFlat   = col_referrer[CMAIN] # no idea what is it? | 13
    colorSetLight[gDefault].fillOutset = col_referrer[CMAIN] # main contents (e.g. button colour)
    colorSetLight[gDefault].fillInset  = col_referrer[CACTV] # fill when clicked

    colorSetLight[gDefault].sliderFill   = 13
    colorSetLight[gDefault].sliderHandle = 7
    colorSetLight[gDefault].sliderTray   = 5

    for outcome in gDefault.succ..GuiOutcome.high:
        colorSetLight[outcome] = colorSetLight[gDefault]

    colorSetLight[gGood].textInset = 11
    colorSetLight[gGood].hoverOutline = 11
    colorSetLight[gGood].fillOutset = 11
    colorSetLight[gGood].outlineInsetLit = 11
    colorSetLight[gGood].outlineOutset = 11
    colorSetLight[gGood].fillInset = 3
    colorSetLight[gGood].outlineFlat = 3
    colorSetLight[gGood].outlineInset = 3
    colorSetLight[gGood].outlineOutsetDark = 3

    colorSetLight[gWarning].textInset = 9
    colorSetLight[gWarning].hoverOutline = 9
    colorSetLight[gWarning].fillOutset = 9
    colorSetLight[gWarning].outlineInsetLit = 9
    colorSetLight[gWarning].outlineOutset = 9
    colorSetLight[gWarning].fillInset = 4
    colorSetLight[gWarning].outlineFlat = 4
    colorSetLight[gWarning].outlineInset = 4
    colorSetLight[gWarning].outlineOutsetDark = 4

    colorSetLight[gDanger].textInset = 8
    colorSetLight[gDanger].hoverOutline = 8
    colorSetLight[gDanger].fillOutset = 8
    colorSetLight[gDanger].outlineInsetLit = 8
    colorSetLight[gDanger].outlineOutset = 8
    colorSetLight[gDanger].fillInset = 2
    colorSetLight[gDanger].outlineFlat = 2
    colorSetLight[gDanger].outlineInset = 2
    colorSetLight[gDanger].outlineOutsetDark = 2

    colorSetLight[gPrimary].textInset = 12
    colorSetLight[gPrimary].hoverOutline = 12
    colorSetLight[gPrimary].fillOutset = 12
    colorSetLight[gPrimary].outlineInsetLit = 12
    colorSetLight[gPrimary].outlineOutset = 12
    colorSetLight[gPrimary].fillInset = 1
    colorSetLight[gPrimary].outlineFlat = 1
    colorSetLight[gPrimary].outlineInset = 1
    colorSetLight[gPrimary].outlineOutsetDark = 1

    G.colorSets = colorSetLight