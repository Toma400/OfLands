/* Of Lands' Tiled extension, allowing for Tiled maps to output .olm files */
// working on Of Lands maps through Tiled has few limitations:
//  - only first layer will be exported
//  - only one tileset will be used
//  - only .png tileset files are supported
// Extension requires your .oldata file to have the same name as tileset image

var olmMapFormat = {
    name: "Of Lands Map format",
    extension: "olm",

    write: function(map, fileName) {
        // base data
        var tilesets          = map.usedTilesets();
        var tileset_terrain   = tilesets[0].imageFileName.match(String.raw`(\w*.png)`);  // regexed only file name, without path
        var tileset_locations = tilesets[1].imageFileName.match(String.raw`(\w*.png)`);  // regexed only file name, without path
        var tileset_data      = tileset_terrain[0].replace(".png", ".oldata");           // sets .oldata to have the same name as tileset image

        var out = "";
        out = out + "tileset_terrain   = " + String.raw`"${tileset_terrain[0]}"` + "\n";   // for some reason `match` yields two same entries
        out = out + "tileset_locations = " + String.raw`"${tileset_locations[0]}"` + "\n"; // for some reason `match` yields two same entries
        out = out + "data              = " + String.raw`"${tileset_data}"` + "\n";
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

        var file = new TextFile(fileName, TextFile.WriteOnly);
        file.write(out);
        file.commit();
    },
}

tiled.registerMapFormat("of lands map", olmMapFormat)