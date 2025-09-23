#################################################
# PACKING MODULE
# Lists all the files necessary to run the game
# without development bloat
# Yields handy .zip package
#################################################
import zippy/ziparchives except ziparchives_v1
import std/tables

const FILES = [
    "gui/grid.png",
    "gui/gui.png",
    "gui/gui_palette.png",
    "maps/default.olm",    # those to be replaced later
    "maps/default2.olm",
    "maps/tiled.js",
    "tilesets/example.oldata",
    "tilesets/example.png",
    "tilesets/example_palette.png",
    "OfLands.exe",
    "oflands.ini",
    "SDL2.dll"
]

var zippy_table: Table[string, string]
for f in FILES:
    let fread = open(f); defer: close(fread)
    zippy_table[f] = readAll(fread)

let archive = createZipArchive(zippy_table)
writeFile("OfLands.zip", archive)