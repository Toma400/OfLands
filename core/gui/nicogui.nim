import std/tables
import nico/gui
import nico
# OL imports
import ../render/colours
import ../../game
import main

const
  MW = MV*TL  # map width
  SW = W - MW # sidebar width
type
  GUIIcons = enum # helper that directs to `gui.png` indexes for particular icons
    # map modes
    mmTerrain  = 16
    mmFactions = 17

var
  # buttons
  bTURN_padX = TL*2 # padding X
  # -- start coordinates
  bTURN_stX : Pint = MW + bTURN_padX
  bTURN_stY : Pint = H - TL*4
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

proc WORKAROUND_TEXT (text: string, x, y: int | Pint, size : int = 3) =
    # proc that is meant to be replaced with Nico rework on GUI blitting - things like buttons should be able to have text size adjusted
    # but until then, we will just blit text on top of empty GUI objects and call it a day
    useColour(CTFLT) # guess what, we use NicoGUI's colours even
    printc(text, x = x + 100, y = y + 15, size)

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