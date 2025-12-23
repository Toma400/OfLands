import zipfile
import shutil
import os

FILES = [
    "gui/font.png",
    "gui/font.png.dat",
    "gui/grid.png",
    "gui/gui.png",
    "gui/gui.toml",
    # TODO: removed so players can't break their game! "maps/default.olm",    # those to be replaced later
    # TODO: removed so players can't break their game! "maps/default2.olm",
    "maps/tamriel.olm",        # temporary TES stuff
    "maps/tamriel.olf",        # temporary TES stuff
    # "maps/summerset.olm",
    "maps/tiled.js",
    "maps/tiled.md",
    #"music",                   # pure folder!?
    # INCLUDE `tamriel` soundtrack when music works!
    "tilesets/land.oldata",
    "tilesets/land.png",
    "tilesets/locs.oldata",
    "tilesets/locs.png",
    "tilesets/ptr_locs.oldata",   # temporary TES stuff
    "tilesets/ptr_locs.png",      # temporary TES stuff
    "tilesets/factions_ptr.png",  # temporary TES stuff
    "tilesets/resources_ptr.png", # temporary TES stuff
    "tilesets/system.png",
    "OfLands.exe",
    "OfLandsConfigurator.exe",   # probably temporary
    "oflands.ini",
    "ol.ico",
    "ol.png",
    "SDL2.dll",
    "SDL2_image.dll",
]
TILED_BACKUP = [
    # tilesets registered
    "maps/Settlements.tsx",
    "maps/PTR Locations.tsx",
    "maps/Of Lands (Main).tsx",
    "maps/Roads.tsx",
    "maps/Resources.tsx",
    # project files
    "maps/tamriel.tiled-project",
    "maps/tamriel.tiled-session",
    "maps/tamriel.tmx"
]

os.system("compile.bat")

shutil.copy("oflands.ini", "../oflands.ini")

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