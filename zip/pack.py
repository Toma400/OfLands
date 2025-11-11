import zipfile
import os

FILES = [
    "gui/font.png",
    "gui/font.png.dat",
    "gui/grid.png",
    "gui/gui.png",
    "maps/default.olm",    # those to be replaced later
    "maps/default2.olm",
    "maps/tamriel.olm",        # temporary TES stuff
    "maps/tamriel.olf",        # temporary TES stuff
    # "maps/summerset.olm",
    "maps/tiled.js",
    "maps/tiled.md",
    "tilesets/example.oldata",
    "tilesets/example.png",
    "tilesets/locs.oldata",
    "tilesets/locs.png",
    "tilesets/ptr_locs.oldata", # temporary TES stuff
    "tilesets/ptr_locs.png",    # temporary TES stuff
    "tilesets/settlements.png", # not useful RIGHT NOW but will be
    "tilesets/system.png",
    "OfLands.exe",
    "oflands.ini",
    "SDL2.dll"
]
TILED_BACKUP = [
    # tilesets registered
    "maps/Settlements.tsx",
    "maps/PTR Locations.tsx",
    "maps/Of Lands (Main).tsx",
    "maps/Roads.tsx",
    # project files
    "maps/tamriel.tiled-project",
    "maps/tamriel.tiled-session",
    "maps/tamriel.tmx"
]

os.system("compile.bat")

with zipfile.ZipFile("../OfLands.zip", mode="w") as archive:
    for f in FILES:
        with archive.open(f, "w") as fw:
            with open(f"../{f}", "rb") as fr:
                fw.write(fr.read())

with zipfile.ZipFile("../OfLands_TILED_BACKUP.zip", mode="w") as archive:
    for f in TILED_BACKUP:
        with archive.open(f, "w") as fw:
            with open(f"../{f}", "rb") as fr:
                fw.write(fr.read())