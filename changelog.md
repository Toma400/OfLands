# Changelog
Versions:
- [0.1.0](#0.1.0)

### 0.1.0
- Created minimal .olm/.oldata system with its parsers
- Made base game structure with ability to interpret .olm and .oldata files
  - This includes loading maps of any size
- Wrote `tiled.js`, Tiled plugin to export its maps into .olm format
- Made map used by game and grid visibility configurable through .ini file
- Created GUI
  - Custom cursor replacing mouse
  - Clicking on tile highlights it and showcases zoom-in and information about it
    in the sidebar
- Added basic kingdom system recognised and stored by the map
- Added time system, showcased on GUI