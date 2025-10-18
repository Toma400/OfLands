# Roadmap
This list here is non-exhaustive, but also non-declarative planning for features.

### 0.1.0
- Locations (only the ones that can easily have no assignment, e.g. forts)
  - A way to build empty forts to showcase structure & tie them to permanent map data
    - Route mode should be turned into architecture mode?
  - ...if we set kingdom struct, we may go with assignments even, dunno
  - showcase? make a way for in-game placement of location on map
- Settlements system added
  - There should be a button "create settlement" that is enabled:
    - when you don't have any settlements as a kingdom
    - when you highlighted settler
  - ...depending on option above, you'd be able to pick any area, or one that settler
    stands on?
  - optionally, you could be introduced to settler entity first and do initial settlement
    via settler (so the system is more coherent)
- Kingdom system with (for now) one default kingdom with name (set through config)
  - banners as separate tileset? (one that comes with the map and is noted in
    .olm, and kingdoms would direct index to it - would make it as value in Kingdom
    struct)
- Save-wise (later) it would make sense to keep names of tilesets in Map struct
- Making sure .oldata tiles can be skipped or not have a name

### 0.2.0
- More tiles
  - Natural
    - rivers
  - Features
    - roads
    - bridges
- Road system
- Tile features (e.g. locations, roads) represented in .olm file
  - includes Tiled integration expanded
  - separated tileset?
- Expanding tile data (.oldata) with more base info?
- Minimap? (whole map rendered but scaled 32 times down, thus every cell would take
            1 pixel each - making currently seen window as 30x30 (MV value); 
            we could draw a small square with that value, so we see what area is currently
            seen from whole bigger map, and as we move on bigger map, the small square
            would also follow

### 0.?
- Being able to dump Map object into file and load it afterwards (savegame)
- Scaling up? (60x60 tiles, 15x15 map view, x2 scale (the same system that showcases
  tile highlight))