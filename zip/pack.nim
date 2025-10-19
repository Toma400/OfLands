#################################################
# PACKING MODULE
# Lists all the files necessary to run the game
# without development bloat
# Yields handy .zip package
#################################################
import zippy/ziparchives
import std/strformat
import std/tables
import std/os

const FILES = [
    "gui/font.png",
    "gui/font.png.dat",
    "gui/grid.png",
    "gui/gui.png",
    "maps/default.olm",    # those to be replaced later
    "maps/default2.olm",
    "maps/summerset.olm",
    "maps/tiled.js",
    "maps/tiled.md",
    "tilesets/example.oldata",
    "tilesets/example.png",
    "tilesets/locs.oldata",
    "tilesets/locs.png",
    "OfLands.exe",
    "oflands.ini",
    "SDL2.dll"
]

discard execShellCmd("compile.bat")

#var zippy_table: Table[string, string]
createZipArchive("../", "../OfLands.zip")

#for f in FILES:
#    let fread = open(fmt"../{f}"); defer: close(fread)
#    zippy_table[f] = readAll(fread)

# let archive = createZipArchive(zippy_table)
# writeFile("../OfLands.zip", archive)