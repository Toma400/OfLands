# Tiled integration
Of Lands supports making maps with Tiled software, through its JavaScript plugin
that can be used.

### Order of layers and tilesets
For .olm plugin to recognise layers correctly, you should use landscape layer as your
first (bottom) one, and locations as second. It follows the logic of layers, but there
should be no layers in between these, as plugin recognises them by index (number).
This has a benefit of layer naming having no importance for plugin.

Contrary to that however, tilesets in Tiled are listed alphabetically, meaning using them
by index would require you to care about their naming order. To solve that, they just
require being named in very particular way:
- `Landscape` - is name for tileset used for terrain (landscape layer)
- `Locations` - is name for tileset used for locations (locations layer)

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

#### Locations
- `name` - name of the location
- `bcond` - condition for location to be placed (also on premade map); can use following values:
  - `land`  - can be placed on land tiles
  - `water` - can be placed on water tiles
  - `air`   - can be placed on tiles that do not obstruct sky (most of them)
  - `all`   - can be anywhere