# Roadmap
This list here is non-exhaustive, but also non-declarative planning for features.

### 0.1.0
- Kingdom system with (for now) one default kingdom with name (set through config)
  - banners as separate tileset? (one that comes with the map and is noted in
    .olm, and kingdoms would direct index to it - would make it as value in Kingdom
    struct)
  - with so many tilesets, it would be good to make proc that generates palette
    from image and just store it in `int, [Palette]` equivalent to spritesheet
    (probably new .nim file that handles all that? with Indexes enum to precise context
     and picking proper index)
- Locations (only the ones that can easily have no assignment, e.g. forts)
  - ...or if we set kingdom struct, we may go with assignments even, dunno
- Save-wise (later) it would make sense to keep names of tilesets in Map struct

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