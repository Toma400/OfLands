# Tiled integration
Of Lands supports making maps with Tiled software, through its JavaScript plugin
that can be used to export maps into Of Lands' formats (`olm`, `olf`, `oldata`).

Table of contents:
- [Setting up layer and tilesets](#setting-up-layers-and-tilesets)
  - [Landscape and locations](#----landscape-and-locations----)
  - [Roads](#----roads----)
  - [Factions and settlements](#----factions-and-settlements----)
- [Tilesets metadata](#tilesets-metadata)
  - [Landscape](#----landscape----)
  - [Locations](#----locations----)
  - [Settlements](#----settlements----)
- [Additional metadata](#additional-metadata)

### Setting up layers and tilesets
Of Lands functions upon multiple layers and tilesets, although not every single one
of them are essential.

#### --- Landscape and locations ---
Landscape and location layers and tilesets are required for the game to start. They are
base building blocks for .olm/.oldata files.

To create landscape and location layers, simply make tile layers called `Landscape` and
`Locations`, respectively.  
Samely, initialise tilesets named the same way. When putting tiles of respective tileset,
you will be able to export this data to OL files.

Mind you, creating tilesets and layers and putting tiles on map isn't enough for OL map
system to properly export. See [here](#----landscape----) and [here](#----locations----)
for what is additionally needed.

#### --- Roads ---
Roads are currently supported only as a ghost data - it gets exported, but doesn't
get read by the game. You can sketch out the roads however for when this feature is
available.

To make roads exported, simply create layer named `Roads`. The layer is optional, so
not having it in the Tiled map won't cause any issues during export.  
Next, use tileset that will have indexes `1` and `2` available (so, second and third
tile). Index 1 (second tile) is dirt road, while index 2 (third tile) is stone road.  
You can use some placeholder icons to visualise roads placed.

#### --- Factions and settlements ---
To add factions, you need to open map properties (`Map > Map Properties` in menu).
Creating faction is as simple as just adding new string property named `kingdom_x_name`,
with `x` replaced by numbers from 1 up. The value of the property will be faction's name.  
It's worth adding however that adding multiple factions, their numbers should be always
increased by one - if there's a number gap in between factions, the ones after the gap
won't be exported.  
Faction number (`x`) will be important.

To create settlements, you need to create `Settlements` layer and tileset. Layer controls
placement of settlements, while tileset defines data.  
Once created, initialise all needed properties for the tile you want to be settlement
marker (you can find properties in [this subsection](#----settlements----)). You can
use some placeholder icons to mark settlements, as the images of settlement tiles won't
be used.

### Tilesets metadata
Making tilesets, you can use Tiled's metadata feature to export .oldata and .olf files.
Depending on tileset type, it will require you to have different metadata to allow 
.oldata/.olf to be created.

#### --- Landscape ---
- `name` _: string_ - name of the tile
- `lbase` _: string_ - base the tile uses; dictates things like movability of building conditions;
            can use following values:
  - `land` - contains primarily landmass
  - `water` - contains primarily water
  - `lava` - for lava streams or lakes
  - `void` - for special uses
- `mv_cost` _: integer_ - cost of movement through the tile; for reference:
  - `15` is default movement across normal tile (takes normal entity 1 turn)
  - movement cost with road is calculated separately by decreasing the base cost

#### --- Locations ---
- `name` _: string_ - name of the location
- `bcond` _: string_ - condition for location to be placed (also on premade map); can use following values:
  - `land`  - can be placed on land tiles
  - `water` - can be placed on water tiles
  - `submerged` - can be placed on both land and water tiles
  - `air`   - can be placed on tiles that do not obstruct sky (most of them)
  - `all`   - can be anywhere

#### --- Settlements ---
- `kingdom` _: integer_ - faction number the settlement belongs to (must be positive)
- `name` _: string_ - name of the settlement (optional)
- `tier` _: string_ - tier of the settlement, one of following:
  - `village`
  - `town`
  - `city`
  - `polis`

### Additional metadata
Additionally, you can set map's starting coordinates by adding `start_coords` property
to map itself. The property should be string, but contain `int, int` data (e.g. `128, 128`)
as it will be transferred in such form to .olm file.