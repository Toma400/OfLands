# Changelog
Versions:
- [0.1.0](#0.1.0)

### 0.1.0
- Created minimal .olm/.oldata system with its parsers
- Made base game structure with ability to interpret `.olm` and `.oldata` files
  - This includes loading maps of any size (bigger than 30x30)
- Wrote `tiled.js`, Tiled plugin to export its maps into `.olm` format
  - It also supports custom properties that are exported into `.oldata` file
- Made map used by game and grid visibility configurable through `.ini` file
- Created GUI
  - Custom cursor replacing mouse
  - Clicking on tile highlights it and showcases zoom-in and information about it
    in the sidebar
- Added time system, showcased on GUI
  - Winter is also seen on tiles that can change their appearance as the season comes
- Added location system, including rendering of locations put on map
  - Made rendering of locations (with ones from premade map being `faction=0`) with
    their info shown when tile is highlighted
  - Locations are automatically removed from premade maps if they don't follow proper
    conditions for building
- Added entities system
- Added basic factions system recognised and stored by the map
  - Locations, settlements and entities affiliated are marked accurately
  - Factions can be initialised with custom `.olf` file and joined by using Configurator
  - Factions have their unique banners
- Added settlement system
  - Settlements have unique icon, depending on their tier and location
  - Settlements can be initialised with custom `.olf` file
- Added road system
- Added turn system, advancing game time
- Added initial starting mode, which requires you to drop settler on some 
  walkable tile (if you don't have settlement)
- Added map modes, allowing you to see either map with terrain and features, or faction
  overlay showcasing political influences
- Included Configurator to serve as placeholder starting tool before proper "new game"
  menu is made
- Game and Configurator have icons both in-game and embed into executable