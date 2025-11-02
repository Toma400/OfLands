# Changelog
Versions:
- [0.1.0](#0.1.0)

### 0.1.0
- Created minimal .olm/.oldata system with its parsers
- Made base game structure with ability to interpret .olm and .oldata files
  - This includes loading maps of any size (bigger than 30x30)
- Wrote `tiled.js`, Tiled plugin to export its maps into .olm format
  - It also supports custom properties that are exported into .oldata file
- Made map used by game and grid visibility configurable through .ini file
- Created GUI
  - Custom cursor replacing mouse
  - Clicking on tile highlights it and showcases zoom-in and information about it
    in the sidebar
- Added basic kingdom system recognised and stored by the map
  - Locations, settlements and entities affiliated are marked accurately
- Added time system, showcased on GUI
- Added location system, including rendering of locations put on map
  - Made rendering of locations (with ones from premade map being `faction=0`) with
    their info shown when tile is highlighted
  - Locations are automatically removed from premade maps if they don't follow proper
    conditions for building
- Added entities system
- Added settlement system
- Added turn system
- Added initial starting mode, which requires you to drop settler on some walkable tile