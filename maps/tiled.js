/* Of Lands' Tiled extension, allowing for Tiled maps to output .olm files */
// working on Of Lands maps through Tiled has few limitations:
//  - only first layer will be exported
//  - you need to use `Landscape` name for terrain tileset, and `Locations` for location one
//  - only .png tileset files are supported
// Extension requires your .oldata file to have the same name as tileset image

var olmMapFormat = {
    name: "Of Lands Map format",
    extension: "olm",

    write: function(map, fileName) {
        // base data
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
            for (y = 0; y < layer.height; ++y) {
                out = out + "    [";
                for (x = 0; x < layer.width; ++x)
                    out = out + layer.cellAt(x, y).tileId + ",";
                out = out + "],\n";
            }
        }

        out = out + "]\n";
        out = out + "locations = [" + "\n";

        var layer = map.layerAt(1); // locations
        if (layer.isTileLayer) {
            for (y = 0; y < layer.height; ++y) {
                out = out + "    [";
                for (x = 0; x < layer.width; ++x)
                    out = out + layer.cellAt(x, y).tileId + ",";
                out = out + "],\n";
            }
        }

        out = out + "]";

        // the main .olm file
        var file = new TextFile(fileName, TextFile.WriteOnly);
        file.write(out);
        file.commit();
    },
}

tiled.registerMapFormat("of lands map", olmMapFormat)