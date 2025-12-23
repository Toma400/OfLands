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
  - [Factions](#----factions----)
- [Additional map metadata](#additional-map-metadata)
  - [Starting coordinates](#----starting-coordinates----)
  - [Starting date](#----starting-date----)
- [Non-Tiled moddability](#non-tiled-moddability)
  - [GUI colours](#----gui-colours----)

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
To make roads, simply create layer named `Roads`. The layer is optional, so
not having it in the Tiled map won't cause any issues during export.  
Next, use tileset that will have indexes `1` and `2` available (so, second and third
tile). Index 1 (second tile) is dirt road, while index 2 (third tile) is stone road.  
You can use some placeholder icons to visualise roads placed.

#### --- Factions and settlements ---
Factions are registered in two steps: first, you should state the amount of registered
kingdoms in map properties. Head to `Map > Map Properties` in menu, and add property
`factions_count` (of integer type) - the number stated there will make game check for
this number of factions on faction tileset.

Next step is making tileset, shared between faction registry and settlement one. It
should be named `Factions` and contain at least amount of tiles equal to faction count
set above.  
Faction registry works by checking amount of tiles equal to this count - iterating
over tiles' data and art, respectively for faction's information and icon visible in-game.

Any tiles past that count can be used freely for settlement markers - they do not need
to have any art, as the marker only matters by its ID placed on map and data stored on
tile. Therefore it is important to also create `Settlements` layer, where settlement
markers can be put.  
This is a good opportunity to use placeholder icons for the settlement marker, as it can
help you with indicating what particular marker represents. It is however crucial to
include all required properties (which can be found [here](#----settlements----)) of
settlement marker for it to be recognised as settlement and registered by the game.

Faction number required by settlement is faction's index + 1 (so, it starts from
number 1 (being index 0 on tileset)).

### Tilesets metadata
Making tilesets, you can use Tiled's metadata feature to export .oldata and .olf files.
Depending on tileset type, it will require you to have different metadata to allow 
.oldata/.olf to be created.

#### --- Landscape ---
- `name` _: string_ - name of the tile
- `lbase` _: string_ - base the tile uses; dictates things like movability or building conditions;
            can use following values:
  - `land` - contains primarily landmass
  - `water` - contains primarily water
  - `lava` - for lava streams or lakes
  - `void` - for special uses
- `mv_cost` _: integer_ - cost of movement through the tile; for reference:
  - `15` is default movement across normal tile (takes normal entity 1 turn)
  - movement cost with road is calculated separately by decreasing the base cost
- winter data - if you want to have winter variant of the tile, there's optional data you can add:
  - `winter_tile` - index of tile to be used for winter appearance (if doesn't exist,
                    defaults to regular appearance)
  - `winter_mv_cost` - cost of movement (if doesn't exist, the `winter_tile`'s movement
                       is used (so if this value doesn't exist, it's value of `mv_cost`))

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
  - `castle` - special; fortified settlement or castle/chapel
  - `tent` - special; tent village

#### --- Factions ---
- `name` _: string_ - name of the faction
- `description` _: string_ - description of what the faction is (optional)
- `start_coords` _: string, string_ - two coordinates indicating starting position when
                                      playing this particular faction (optional);
                                      see also relevant note on `0, 0` coords [here](#----starting-coordinates----)

### Additional map metadata
Additionally to the above, you can also set some data to the map itself. You can enter
it by clicking on `Map > Map Properties`.

#### --- Starting coordinates ---
You can set map's starting coordinates by adding `start_coords` property. The property
should be string, but contain `int, int` data (e.g. `128, 128`) as it will be transferred
in such form to .olm file.  
Mind you, faction starting coordinates take priority over map ones. If no property is
set, default value is `0, 0`.

**NOTE**: Do not set value `0, 0` if you add this property - for some reason Of Lands'
file parser has issues with collection of pure zeroes. Mark it as `1, 1`, or just do
not add property since the default will set you at this exact area.

#### --- Starting date ---
Default date map is set with is 1st January, of year 1. If you want to set it to different
value, create `start_date` property. It should be string type, but contain `int, int, int`
value (e.g. `300, 10, 1`). The date format goes in order of year, month and day. You can
set less values (e.g. just year) but keep in mind any values past three will be skipped.  
Also be careful to not set month or day values that would be impossible in regular
calendar, as it can result in crashing the game.

### Non-Tiled moddability
While most things are editable through Tiled directly, some of more miscellaneous aspects
of the game need direct changes to files.

#### --- GUI colours ---
To edit colours of GUI (that are not set in `gui.png` tileset), open (or create, if the
file doesn't exist) `gui.toml` file in `gui` folder.  
Next, write or edit any of following keys to set their values:
- `text` - colour of regular game text
- `warn` - colour of warnings and GUI elements related
- `main` - colour of GUI elements (buttons etc.) when idle
- `active` - colour of GUI elements (buttons etc.) when clicked
- `outline` - outline of GUI elements (buttons etc.) when idle
- `hover_ol` - outline of GUI elements (buttons etc.) when hovered
- `text_flt` - text on GUI elements (buttons etc.), flat
- `text_ins` - text on GUI elements (buttons etc.), inset
- `text_ots` - text on GUI elements (buttons etc.), outset
- `text_dis` - text on GUI elements (buttons etc.), disabled

Key values are meant to be array of three `uint8` (numbers of range 0-255) values, 
representing respective RGB value.  
Example: `[128, 128, 128]`  
**Important note**: using `[0, 0, 0]` will produce crash due to Of Lands' file parser
bug, so in this case it's recommended to use values such as `1, 1, 1`

If respective key is not filled, the default value will be used. Default values can
be seen in [this file](/core/render/colours.nim), under `basePalette.COLS` table.