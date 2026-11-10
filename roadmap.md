# Roadmap
This list here is non-exhaustive, but also non-declarative planning for features.

Ideas for versioning:
- 0.1.x - basic features, implementation of surface systems/objects
- 0.2.x - game-breaking, technical revamps
- 0.3.x - actual gameplay introduction

### 0.1.1.
- resources in settlements
  - visible feedback of stored resources that wraps up so it doesn't overflow GUI
    - check for some GUI elements in Nico
    - try to include this for locations also
- resources
  - proper requirements for their registration and expanded properties
  - what is optional should be actually optional, `name` should be registry requirement?
- technical
  - map versioning? for now simple == equaling, later on could work like IoA dependency
- debloat of the code, making more map data/files optional
  - use `files.nim` to debloat `game.nim`
- Tamriel map expansion
  - continuing High Rock kingdoms/landmass
  - registering more resources
- location as `ref object` and with added storage capacity (as metadata) and equivalent procs
- exporter: separate Tamriel map from pack, so no-map version can be uploaded upon release
  - laptop: provide "vanilla" map for release

### 0.1.2.
- resource limits (straight for now, but code to be extendable with upgrades)
- locations' resources producing (to see increase of items, and then reaching the cap)
  - GUI
    - any management GUI would only appear in case of owning settlement
    - resource count requires either ownership _or_ entity standing on it? (semi-fog
      of war)
  - possibly boolean on `active/inactive` for location
    - switchable manually? and switchable automatically if cap is reached
    - automatic one could unswitch or something (registering different context)
      - could have `[x] tick` GUI for enabling unswitch
- system for faction owned locations

### 0.1.3.
- entities' movement
  - system for 'planning' the move and calculating cost/turn count
  - per-tile differences in speed
- claimage of unowned locations
- entity storage
- ability for entity to take resources from same-faction tile
- ability for entity to drop resources onto same-faction tile
- automation `possible 0.1.4 feature split if 0.1.3 scope is deemed too big`
  - system for 'planning' the automated routes
  - automating the movement?
  - automating the pickup?
  - automating the drop?
  - handling the errors (e.g. no resources to take, reaching cap on delivery place)
- entities production in cities?? `possible 0.1.4 too`
  - requires location producing food
  - would test the pipeline of (automating) delivery > hiring from resources produced
  - would test ability to increase delivery by increasingly more entities involved
- food/money consumption? `possible 0.1.4 too`
  - entity having health bar/food needs, restored upon eating food periodically
  - management system of automatically feasting if below particular level?
  - degrading health with starvation? slower movement? perishing upon reaching 0 hp?
  - question: should food be restored w/o cost in cities, or with lesser cost?
    - management system prioritising city feast over "below level" one? (to save food)
  - lack of payment could queue but lower the morale? (what morale would be used for
    outside of army?)

### 0.2.0.
- tile system rework?? think this through and _fully_ finalise design doc/planning
  before that to have clear road forward (0.2.0)
- importable .olm/.olr/.olf? (0.2.1 - after all map-specific pieces are done)
  - cheatsheet generator for resources/factions in Tiled?
- resolution adjustability (0.2.2)
- road performance improvements (0.2.3)
- ... (0.2.4+)

### 0.3.0.
- culture contextuality (locations/settlements/entities per culture?)
- [settlement buildings/system drawing them correctly]
  - limits on buildings per tier
  - settlement tier advancing?
  - resource requirements (possible to achieve with pre-made locations? and if entity
    system has builders at this point, they could also setup locations)
  - storage = upping the storage cap

### General todo
- **REWORKS**
  - Tile system being separated onto "background" and "top" (e.g. forest layer and grass
    layer)
    - this allows for huge versatility of designs, e.g. forests in combinations that would
      normally require ton of additional tile copies
    - mix-matching region/region objects could also exist for borders
    - deforestation etc. could likely be done through "upper tile" context
  - custom format
    - make example files/blank map
    - make .olf/.olm/etc. importable
    - make files more optional/have fallback
    - ^ above only makes sense if Tile system is reworked/agreed on
  - adjustable resolution?
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

### 0.1.x
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

### 0.2.x
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
- Fog of war, with certain distances enabled by owned settlements, locations and entities