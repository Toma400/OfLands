# Tiled integration
Of Lands supports making maps with Tiled software, through its JavaScript plugin
that can be used.

### Order of layers and tilesets
For .olm plugin to recognise layers correctly, you should use landscape layer as your
first (bottom) one, and locations as second. It follows the logic of layers, but there
should be no layers in between these, as plugin recognises them by index (number).
This has a benefit of layer naming having no importance for plugin.  
Additionally, there's third layer that can include roads, but it is not a feature that
works in Of Lands as of now.

Contrary to that however, tilesets in Tiled are listed alphabetically, meaning using them
by index would require you to care about their naming order. To solve that, they just
require being named in very particular way:
- `Landscape` - is name for tileset used for terrain (landscape layer)
- `Locations` - is name for tileset used for locations (locations layer)
- `System` - is name for tileset used for all other features (e.g. entities)

Of course file names can be different, the importance here is only for project's naming
of the tileset.

### Tilesets metadata
Making tilesets, you can use Tiled's metadata feature to export .oldata files. Depending
on tileset type, it will require you to have different metadata to allow .oldata to be
created.

#### Landscape
- `name` - name of the tile
- `lbase` - base the tile uses; dictates things like movability of building conditions;
            can use following values:
  - `land` - contains primarily landmass
  - `water` - contains primarily water
  - `lava` - for lava streams or lakes
  - `void` - for special uses
- `mv_cost` - cost of movement through the tile; for reference:
  - `15` is default movement across normal tile (takes normal entity 1 turn)
  - movement cost with road is calculated separately by decreasing the base cost

#### Locations
- `name` - name of the location
- `bcond` - condition for location to be placed (also on premade map); can use following values:
  - `land`  - can be placed on land tiles
  - `water` - can be placed on water tiles
  - `air`   - can be placed on tiles that do not obstruct sky (most of them)
  - `all`   - can be anywhere

### Additional metadata
Additionally, you can set map's starting coordinates by adding `start_coords` property
to map itself. The property should be string, but contain `int, int` data (e.g. `128, 128`)
as it will be transferred in such form to .olm file.