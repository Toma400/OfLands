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