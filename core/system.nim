import parsecfg
export parsecfg
###################################################################
const GAME_NAME* = "Of Lands"
const AUTHOR*    = "Toma400"
const LICENSE*   = "All Rights Reserved (C) Tomasz Stępień 2025"
###################################################################
let cfg* = loadConfig("oflands.ini")
#------------------------------------------------------------------
# Statics (values not meant to be editable)
let GAME_VER* = getSectionValue(cfg, "", "version") # taken out of `const` field as now dependent on config