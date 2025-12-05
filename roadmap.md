# Roadmap
This list here is non-exhaustive, but also non-declarative planning for features.

### Nearest todo
- **CODE**
  - Roads
    - improvement to performance
      - use of threadpools 
      - data check by chunks, with smart system going outwards from chunk player spawn in
    - checks for placement and potential routes (roads should not always go in
      all 8 directions, see mountains or bridges?)
  - GUI
    - fix Nico's GUI text size
    - **create proper theme with custom colours**
  - Entities moving
    - make list of entities on particular tile and let player select entity
    - when selected, let player move the entity and show the "path" with cost per tile
      (and summed up)
      - make movement "accumulate" travel points and let this reset only after
        travel is done (meaning if you change route during travel, it would keep
        the progress)
  - Locations
    - make locations' ownership binding possible on factions' file (also via Tiled)
      - colours could be inherited from banners, randomised, or custom - in the last
        case however we would need to make them work with palette registry *and* make
        a way for OL to know what index to point at (see [#6 GH's issue](https://github.com/Toma400/OfLands/issues/6#issuecomment-3616103920)
        that has similar concern re: colours)
  - Settlements
    - list of resources in the particular tile/settlement, with amounts
  - [Emscripten pipeline to support Linux/MacOS?](https://github.com/treeform/nim_emscripten_tutorial)
  - Factions
    - button to special mode where it would show faction alignment through colours
      - colours would need to be a part of palette somehow
  - Other
    - fix palette issue
    - check optionality of data (both in Tiled exporter and OL's importer)
- **TILESETS**
  - more regular textured tiles (actual meadow, trees v2, grass?, singular tree?) 
  - mountains & cliffs
    - hill type following these?
  - more vanilla regions
  - split off PTR map at that point (and include PTR regions then!)
- **TILED INTEGRATION & TOOLING**
  - plugin for specific shifting
    - single ID shift (e.g. 5 -> 30)
      - useful for changes like moving that dumb rock
    - mass ID shift (.toml file with `A -> B` pairs)
      - will be super useful for future landmass tileset?
  - deAI current plugin for god's sake
    - fix negative moves 

### 0.1.0
- Locations (only the ones that can easily have no assignment, e.g. forts)
  - A way to build empty forts to showcase structure & tie them to permanent map data
    - Route mode should be turned into architecture mode?
  - ...if we set kingdom struct, we may go with assignments even, dunno
  - TODO: Make something to indicate their type (e.g. if it's fort or something else) and how
    this reflects further relation (e.g. how ruined fort is connected to fort)
    - probably should work like `deforestation` does for landscape (`repair` data?)
  - showcase? make a way for in-game placement of location on map
- Settlements system added
  - There should be a button "create settlement" that is enabled:
    - when you don't have any settlements as a kingdom
    - when you highlighted settler
  - ...depending on option above, you'd be able to pick any area, or one that settler
    stands on?
  - optionally, you could be introduced to settler entity first and do initial settlement
    via settler (so the system is more coherent)
- Save-wise (later) it would make sense to keep names of tilesets in Map struct
- Making sure .oldata tiles can be skipped or not have a name

### 0.2.0
- More tiles
  - Natural
    - rivers
  - Features
    - bridges
- Expanding tile data (.oldata) with more base info?

### 0.?
- Being able to dump Map object into file and load it afterwards (savegame)
- Scaling up? (60x60 tiles, 15x15 map view, x2 scale (the same system that showcases
  tile highlight))