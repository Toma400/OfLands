/* Of Lands' Tiled extension, allowing for Tiled maps to output .olm files */
// See `Tiled.md` file for actual guide on how to work with Tiled to create
// proper Of Lands maps

var olmMapFormat = {
    name: "Of Lands Map format",
    extension: "olm",

    outputFiles: function(map, fileName) {
        const baseName = fileName.substring(0, fileName.lastIndexOf("."));
        return [baseName + "olm", baseName + "olf", baseName + "oldata"];
    },

    write: function(map, fileName) {
        // base data
        const baseName        = fileName.substring(0, fileName.lastIndexOf("."));
        const baseDir         = fileName.substring(0, fileName.lastIndexOf("/"));
        const pureName        = fileName.substring(fileName.lastIndexOf("/") + 1, fileName.lastIndexOf("."))
        var tilesets          = map.tilesets;
        var tilesets_dict     = tilesets.reduce(function(dict, x) { // it does convert list to dict actually lol
                                    dict[x.name] = x;
                                    return dict;
                                }, {});
        var layers            = map.layers;
        var layers_dict       = layers.reduce(function(dict, x) { // it does convert list to dict actually lol
                                    dict[x.name] = x;
                                    return dict;
        }, {});
        var faction_count     = "factions_count" in map.properties() ? map.property("factions_count") : 0;
        // TODO: make faction tileset optional!!!!!!
        var tileset_terrain   = tilesets_dict["Landscape"].imageFileName.match(String.raw`(\w*.png)`);  // regexed only file name, without path
        var tileset_locations = tilesets_dict["Locations"].imageFileName.match(String.raw`(\w*.png)`);  // regexed only file name, without path
        var tileset_factions  = tilesets_dict["Factions"].imageFileName.match(String.raw`(\w*.png)`);   // regexed only file name, without path
        var tileset_system    = tilesets_dict["System"].imageFileName.match(String.raw`(\w*.png)`);     // regexed only file name, without path
        var data_terrain      = tileset_terrain[0].replace(".png", ".oldata");           // sets .oldata to have the same name as tileset image
        var data_locations    = tileset_locations[0].replace(".png", ".oldata");         // sets .oldata to have the same name as tileset image

        // factions
        if (faction_count > 0 && "Factions" in tilesets_dict) {
            var olf           = ""; // output file string
            var faction_tiles = tilesets_dict["Factions"].tiles;

            for (let faction_ix = 0; faction_ix < faction_count; faction_ix++) {
                var faction_tile = faction_tiles[faction_ix];
                var faction_prop = faction_tile.properties();
                olf = olf + `[kingdom.${faction_ix + 1}]`                          + "\n"; // header
                if ("name" in faction_prop) {
                    olf = olf + "name = " + String.raw`"${faction_tile.property('name')}"` + "\n";
                }
                if ("start_coords" in faction_prop) {
                    olf = olf + "start_coordinates = " + "[" + faction_tile.property("start_coords") + "]\n";
                }
            }
//            for (const kingdom_nb of Array(999).keys()) { // checks for kingdom registry, needs to have consecutive numbers
//                var kingdom_var = `kingdom_${kingdom_nb + 1}_name`
//                if (kingdom_var in map.properties()) {
//                    olf = olf + `[kingdom.${kingdom_nb + 1}]`                          + "\n"; // header
//                    olf = olf + "name = " + String.raw`"${map.property(kingdom_var)}"` + "\n";
//                } else {
//                    break; // breaks when finds the gap
//                }
//            }
            if ("Factions" in tilesets_dict) {
                var settlements = tilesets_dict["Factions"].tiles;
                for (const settlement of settlements) {
                    if (settlement.id >= faction_count) { // skips faction registry
                        // checks if tile has data (required & optional)
                        var settlement_properties = settlement.properties();
                        if (("kingdom" in settlement_properties) && ("tier" in settlement_properties) && ("name" in settlement_properties)) {
                            // checks if tile has properly set required data
                            if ((settlement.property("kingdom") != 0) && (settlement.property("tier") != "")) {
                                olf = olf + `[settlement.${settlement.id}]`                             + "\n";
                                olf = olf + "kingdom = " + settlement.property("kingdom")               + "\n";
                                olf = olf + "name    = " + String.raw`"${settlement.property('name')}"` + "\n";
                                olf = olf + "tier    = " + String.raw`"${settlement.property('tier')}"` + "\n";
                            }
                        }
                    }
                }
            }
            if ("Settlements" in layers_dict) {
                var layer = layers_dict["Settlements"]; // terrain
                if (layer.isTileLayer) {
                    olf = olf + "[map]"           + "\n";
                    olf = olf + "settlements = [" + "\n";
                    for (var y = 0; y < layer.height; ++y) {
                        olf = olf + "    [";
                        for (var x = 0; x < layer.width; ++x)
                            olf = olf + layer.cellAt(x, y).tileId + ",";
                        olf = olf + "],\n";
                    }
                }
                olf = olf + "]\n";
            }
            if (olf.length > 0) {
                var factionFile = new TextFile(baseName + ".olf", TextFile.WriteOnly); // writes .olf named samely as map
                factionFile.write(olf);
                factionFile.commit();
            }
        }

        // .olm file contents
        var out = "";
        if ("start_coords" in map.properties()) { // optional
            out = out + "start_coordinates = " + "[" + map.property("start_coords") + "]\n";
        }
        if (olf.length > 0) { // if kingdoms are registered
            out = out + "factions          = " + String.raw`"${pureName}.olf"` + "\n";
        }
        out = out + "tileset_terrain   = " + String.raw`"${tileset_terrain[0]}"` + "\n";   // for some reason `match` yields two same entries
        out = out + "tileset_locations = " + String.raw`"${tileset_locations[0]}"` + "\n"; // for some reason `match` yields two same entries
        out = out + "tileset_factions  = " + String.raw`"${tileset_factions[0]}"` + "\n";  // for some reason `match` yields two same entries
        out = out + "tileset_system    = " + String.raw`"${tileset_system[0]}"` + "\n";    // for some reason `match` yields two same entries
        out = out + "data_terrain      = " + String.raw`"${data_terrain}"` + "\n";
        out = out + "data_locations    = " + String.raw`"${data_locations}"` + "\n";
        out = out + "terrain = [" + "\n";

        var layer = layers_dict["Landscape"]; // terrain
        if (layer.isTileLayer) {
            for (var y = 0; y < layer.height; ++y) {
                out = out + "    [";
                for (var x = 0; x < layer.width; ++x)
                    out = out + layer.cellAt(x, y).tileId + ",";
                out = out + "],\n";
            }
        }

        out = out + "]\n";
        out = out + "locations = [" + "\n";

        var layer = layers_dict["Locations"]; // locations
        if (layer.isTileLayer) {
            for (var y = 0; y < layer.height; ++y) {
                out = out + "    [";
                for (var x = 0; x < layer.width; ++x)
                    out = out + layer.cellAt(x, y).tileId + ",";
                out = out + "],\n";
            }
        }

        if ("Roads" in layers_dict) { // optionals
            out = out + "]\n";
            out = out + "roads = [" + "\n";

            var layer = layers_dict["Roads"]; // roads
            if (layer.isTileLayer) {
                for (var y = 0; y < layer.height; ++y) {
                    out = out + "    [";
                    for (var x = 0; x < layer.width; ++x)
                        out = out + layer.cellAt(x, y).tileId + ",";
                    out = out + "],\n";
                }
            }
        }

        out = out + "]";

        // the main .olm file
        var olmFile = new TextFile(baseName + ".olm", TextFile.WriteOnly);
        olmFile.write(out);
        olmFile.commit();

        // location .oldata parsing
        var locdata = "";
        for (var i = 0; i < tilesets_dict["Locations"].tiles.length; ++i) {
            var tile      = tilesets_dict["Locations"].tiles[i];
            var tile_data = tile.properties();

            if (Object.keys(tile_data).length > 0) { // skips locations without properties
                locdata += "[tile." + tile.id + "]\n";

                for (var key in tile_data) {
                    var val = typeof tile_data[key] === "string"  ? "\"" + tile_data[key] + "\""
                            : typeof tile_data[key] === "number"  ? tile_data[key]
                            : typeof tile_data[key] === "boolean" ? tile_data[key]
                            : "";
                    locdata += key + " = " + val + "\n";
                }
            }
        }

        // .oldata for locations
        if (locdata.length > 0) { // skips if no properties are set (= user wants to make .oldata manually)
            var locdataFile = new TextFile(baseDir + "/../tilesets/" + data_locations, TextFile.WriteOnly); // writes .oldata in directory of tileset image
            locdataFile.write(locdata);
            locdataFile.commit();
        }

        // terrain .oldata parsing
        var landdata = "";
        for (var i = 0; i < tilesets_dict["Landscape"].tiles.length; ++i) {
            var tile      = tilesets_dict["Landscape"].tiles[i];
            var tile_data = tile.properties();

            if (Object.keys(tile_data).length > 0) { // skips tiles without properties
                landdata += "[tile." + tile.id + "]\n";

                for (var key in tile_data) {
                    var val = typeof tile_data[key] === "string"  ? "\"" + tile_data[key] + "\""
                            : typeof tile_data[key] === "number"  ? tile_data[key]
                            : typeof tile_data[key] === "boolean" ? tile_data[key]
                            : "";
                    landdata += key + " = " + val + "\n";
                }
            }
        }

        // .oldata for terrain
        if (landdata.length > 0) { // skips if no properties are set (= user wants to make .oldata manually)
            var landdataFile = new TextFile(baseDir + "/../tilesets/" + data_terrain, TextFile.WriteOnly); // writes .oldata in directory of tileset image
            landdataFile.write(landdata);
            landdataFile.commit();
        }
    },
}

tiled.registerMapFormat("of lands map", olmMapFormat)