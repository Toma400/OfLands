# Changelog
Versions:
- [0.1.0](#0.1.0)

### 0.1.0
- Created minimal .olm/.oldata system with its parsers
- Made base game structure with ability to interpret .olm and .oldata files
  - This includes loading maps of any size
- Wrote `tiled.js`, Tiled plugin to export its maps into .olm format
  - It also supports custom properties that are exported into .oldata file
- Made map used by game and grid visibility configurable through .ini file
- Created GUI
  - Custom cursor replacing mouse
  - Clicking on tile highlights it and showcases zoom-in and information about it
    in the sidebar
- Added basic kingdom system recognised and stored by the map
- Added time system, showcased on GUI
- Added location system, including rendering of locations put on map
  - Made rendering of locations (with ones from premade map being `faction=0`) with
    their info shown when tile is highlighted
  - TODO: Make something to indicate their type (e.g. if it's fort or something else) and how
    this reflects further relation (e.g. how ruined fort is connected to fort)
    - probably should work like `deforestation` does for landscape (`repair` data?)