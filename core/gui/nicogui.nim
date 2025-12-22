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
  bTURN_on  : bool = true

  # o tempora(ry) o mores
  bFM_stY = bTURN_stY - 50

proc turnButton* (proced: proc) =
    if G.beginWindow("", bTURN_stX, bTURN_stY, bTURN_szX, bTURN_szY, bTURN_on):
        if G.button("End Turn", bTURN_stX, bTURN_stY, bTURN_szX, bTURN_szY):
            proced()
        G.endArea()

proc facmodeButton* (proced: proc) =
    if G.beginWindow("", bTURN_stX, bFM_stY, bTURN_szX, bTURN_szY, bTURN_on):
        if G.button("See Factions", bTURN_stX, bFM_stY, bTURN_szX, bTURN_szY):
            proced()
        G.endArea()

proc initGUITheme* () =
    colorSetLight[gDefault].modalOutline = 0
    colorSetLight[gDefault].windowTitleFillFocused = 12
    colorSetLight[gDefault].windowTitleTextFocused = 7
    colorSetLight[gDefault].windowTitleFill = 1
    colorSetLight[gDefault].windowTitleText = 6

    colorSetLight[gDefault].hoverOutline = 10

    colorSetLight[gDefault].textFlat     = col_referrer[CTFLT]
    colorSetLight[gDefault].textInset    = col_referrer[CTINS]
    colorSetLight[gDefault].textOutset   = col_referrer[CTOTS]
    colorSetLight[gDefault].textDisabled = col_referrer[CTDIS]

    colorSetLight[gDefault].outlineFlat = 5
    colorSetLight[gDefault].outlineInset = 5
    colorSetLight[gDefault].outlineInsetLit = 7
    colorSetLight[gDefault].outlineInsetDark = 1
    colorSetLight[gDefault].outlineOutset = 6
    colorSetLight[gDefault].outlineOutsetLit = 7
    colorSetLight[gDefault].outlineOutsetDark = 1

    colorSetLight[gDefault].fillFlat = 13
    colorSetLight[gDefault].fillOutset = 6
    colorSetLight[gDefault].fillInset = 5

    colorSetLight[gDefault].sliderFill = 13
    colorSetLight[gDefault].sliderHandle = 7
    colorSetLight[gDefault].sliderTray = 5

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