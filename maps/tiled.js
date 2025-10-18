/* Of Lands' Tiled extension, allowing for Tiled maps to output .olm files */
// working on Of Lands maps through Tiled has few limitations:
//  - only first layer will be exported
//  - you need to use `Landscape` name for terrain tileset, and `Locations` for location one
//  - only .png tileset files are supported
// Extension requires your .oldata file to have the same name as tileset image

var olmMapFormat = {
    name: "Of Lands Map format",
    extension: "olm",

    outputFiles: function(map, fileName) {
        const baseName = fileName.substring(0, fileName.lastIndexOf("."));
        return [baseName + "olm", baseName + "oldata"];
    },

    write: function(map, fileName) {
        // base data
        const baseName        = fileName.substring(0, fileName.lastIndexOf("."));
        const baseDir         = fileName.substring(0, fileName.lastIndexOf("/"));
        var tilesets          = map.usedTilesets();
        var tilesets_dict     = tilesets.reduce(function(dict, x) {
                                    dict[x.name] = x;
                                    return dict;
                                }, {});
        var tileset_terrain   = tilesets_dict["Landscape"].imageFileName.match(String.raw`(\w*.png)`);  // regexed only file name, without path
        var tileset_locations = tilesets_dict["Locations"].imageFileName.match(String.raw`(\w*.png)`);  // regexed only file name, without path
        var data_terrain      = tileset_terrain[0].replace(".png", ".oldata");           // sets .oldata to have the same name as tileset image
        var data_locations    = tileset_locations[0].replace(".png", ".oldata");         // sets .oldata to have the same name as tileset image

        var out = "";
        out = out + "tileset_terrain   = " + String.raw`"${tileset_terrain[0]}"` + "\n";   // for some reason `match` yields two same entries
        out = out + "tileset_locations = " + String.raw`"${tileset_locations[0]}"` + "\n"; // for some reason `match` yields two same entries
        out = out + "data_terrain      = " + String.raw`"${data_terrain}"` + "\n";
        out = out + "data_locations    = " + String.raw`"${data_locations}"` + "\n";
        out = out + "terrain = [" + "\n";

        var layer = map.layerAt(0); // terrain
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

        var layer = map.layerAt(1); // locations
        if (layer.isTileLayer) {
            for (var y = 0; y < layer.height; ++y) {
                out = out + "    [";
                for (var x = 0; x < layer.width; ++x)
                    out = out + layer.cellAt(x, y).tileId + ",";
                out = out + "],\n";
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