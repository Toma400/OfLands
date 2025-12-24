// Shift tile references for a specific tileset across the current map.
// - Includes tile layers and tile objects on object layers
// - Wraps all edits in a single undo macro
// - Uses a Dialog to select the tileset and the shift amount
//
// Install: Save as a .js file in your Tiled extensions folder and reload scripts.

function forEachLayer(layer, fn) {
    // Recurse into group layers
    if (layer.isGroupLayer && layer.layers) {
        layer.layers.forEach(l => forEachLayer(l, fn));
        return;
    }
    fn(layer);
}
function forEachLayerInMap(map, fn) {
    map.layers.forEach(l => forEachLayer(l, fn));
}

function eachTileCell(layer, visitor) {
    // Efficiently iterate only the filled region (works for infinite maps too)
    const rgn = layer.region();
    for (const r of rgn.rects) {
        const x0 = r.x;
        const y0 = r.y;
        const x1 = r.x + r.width;
        const y1 = r.y + r.height;
        for (let y = y0; y < y1; y++) {
            for (let x = x0; x < x1; x++) {
                visitor(x, y);
            }
        }
    }
}

function tryGetNewTile(tileset, newId) {
    // Return the tile with id=newId or null when it doesn't exist
    // tileset.tile(id) throws if it doesn't exist, so guard it
    try {
        // Prefer checking within bounds when available
        if (tileset && typeof tileset.tileCount === "number") {
            if (newId < 0 || newId >= tileset.tileCount)
                return null;
        }
        return tileset.tile(newId);
    } catch (e) {
        return null;
    }
}

function shiftTileReferences(map, tileset, shiftBy, shiftFrom) {
    let cellsChanged = 0;
    let objectsChanged = 0;

    map.macro(`Shift tile references in "${tileset.name}" by ${shiftBy}`, function() {
        // Process tile layers
        forEachLayerInMap(map, function(layer) {
            if (!layer || !layer.isTileLayer) {
                return;
            }

            const edit = layer.edit();

            eachTileCell(layer, (x, y) => {
                const tile = layer.tileAt(x, y);
                if (!tile || tile.tileset !== tileset || tile.id < shiftFrom) {
                    return;
                }

                const newId = tile.id + shiftBy;
                const newTile = tryGetNewTile(tileset, newId);
                if (!newTile) {
                    return; // skip when outside valid range
                }

                const flags = layer.flagsAt(x, y); // preserve flips/rotation
                edit.setTile(x, y, newTile, flags);
                cellsChanged++;
            });

            edit.apply();
        });

        // Process tile objects on object layers
        forEachLayerInMap(map, function(layer) {
            if (!layer || !layer.isObjectLayer) {
                return;
            }

            for (const obj of layer.objects) {
                if (!obj.tile || obj.tile.tileset !== tileset || obj.tile.id < shiftFrom) {
                    continue;
                }

                const newId = obj.tile.id + shiftBy;
                const newTile = tryGetNewTile(tileset, newId);
                if (!newTile) {
                    continue; // skip when outside valid range
                }

                obj.tile = newTile;
                objectsChanged++;
            }
        });

        // Process tileset data (properties, terrain, etc.)
        // todo: const oldTiles = [shiftFrom...tileset.tiles]; (not really possible afaik, but still)
        const oldTiles = [...tileset.tiles]; // snapshot
        for (const tile of oldTiles.reverse()) {
            const newId = tile.id + shiftBy;
            const newTile = tryGetNewTile(tileset, newId);
            if (!newTile || tile.id < shiftFrom) { // todo: check for id could be earlier ig
                continue; // skip when outside valid range
            }

            tiled.log(`${tile.id} -> ${newId}`);
            // remove & copy custom properties
            for (const prop in newTile.properties()) {
                tiled.log(prop);
                tiled.log(`- ${prop}`);
                newTile.removeProperty(prop);
            }
            for (const prop in tile.properties()) {
                tiled.log(prop);
                tiled.log(`+ ${prop}: ${tile.property(prop)}`);
                newTile.setProperty(prop, tile.property(prop));
            }
        }
//        // Process tileset data (properties, class, animation)
//        const oldTiles = [...tileset.tiles]; // snapshot of tiles that have data
//        for (const srcTile of oldTiles) {
//            const newId = srcTile.id + shiftBy;
//            const dstTile = tryGetNewTile(tileset, newId);
//            if (!dstTile)
//                continue; // outside valid range
//
//            // Copy custom properties (use PropertySet API)
//            // Clear destination properties first
//            for (const name of dstTile.propertyNames())
//                dstTile.removeProperty(name);
//            // Copy all source properties
//            for (const name of srcTile.propertyNames())
//                dstTile.setProperty(name, srcTile.property(name));
//
//            // Copy tile class (Tiled 1.9+)
//            dstTile.class = srcTile.class;
//
//            // Copy animation frames and shift their tile references, if present
//            if (srcTile.frames && srcTile.frames.length) {
//                const shiftedFrames = [];
//                for (const frame of srcTile.frames) {
//                    const frameTile = frame.tile;
//                    const shiftedFrameTile = (frameTile && frameTile.tileset === tileset)
//                        ? tryGetNewTile(tileset, frameTile.id + shiftBy)
//                        : frameTile; // keep cross-tileset refs unchanged
//                    shiftedFrames.push({ tile: shiftedFrameTile, duration: frame.duration });
//                }
//                dstTile.setAnimation(shiftedFrames);
//            } else {
//                // Ensure no stale animation remains
//                dstTile.setAnimation([]);
//            }
//        }
    });

    return { cellsChanged, objectsChanged };
}

var action = tiled.registerAction("ShiftTileReferencesWithDialog", function() {
    const asset = tiled.activeAsset;
    if (!asset || !asset.isTileMap) {
        tiled.alert("No active map.");
        return;
    }

    const map = asset;
    const tilesets = map.tilesets || [];
    if (tilesets.length === 0) {
        tiled.alert("The current map has no referenced tilesets.");
        return;
    }

    // Build Dialog
    const dialog = new Dialog("Mass Shift Tile References");

    const tilesetNames = tilesets.map(ts => ts.name);
    const tilesetCombo = dialog.addComboBox("Tileset", tilesetNames);

    const shiftInput = dialog.addNumberInput("Shift by (can be negative):");
    shiftInput.decimals = 0;
    shiftInput.minimum = -999999;
    shiftInput.maximum = 999999;
    shiftInput.value = 0;

    const shiftStartingIndex = dialog.addNumberInput("Shift from index:");
    shiftStartingIndex.decimals = 0;
    shiftStartingIndex.minimum  = -999999;
    shiftStartingIndex.maximum  = 999999;
    shiftStartingIndex.value    = 0;

    // Dialog buttons
    const okBtn = dialog.addButton("OK");
    const cancelBtn = dialog.addButton("Cancel");
    okBtn.clicked.connect(() => {
	    // Resolve selected tileset
	    const selectedIndex = tilesetCombo.currentIndex;
	    // todo: tiled.log(`Selected tileset index: ${selectedIndex}`);
	    const selectedTileset = tilesets[selectedIndex] || null;
	    if (!selectedTileset) {
	        tiled.alert("No tileset selected.");
	        return;
	    }

	    // Resolve shift amount
	    const shiftBy = Math.trunc(shiftInput.value);
	    if (!Number.isFinite(shiftBy)) {
	        tiled.alert("Shift amount must be an integer.");
	        return;
	    }

	    // Resolve shift start amount
	    const shiftFrom = Math.trunc(shiftStartingIndex.value);
	    if (!Number.isFinite(shiftFrom) || shiftFrom < 0) {
	        tiled.alert("Shift starting index must be an integer and have non-negative (0-...) value.");
	        return;
	    }

	    const { cellsChanged, objectsChanged } = shiftTileReferences(map, selectedTileset, shiftBy, shiftFrom);
	    tiled.alert(`Shift complete for tileset "${selectedTileset.name}".\n` +
	                `Updated ${cellsChanged} tile cell(s) and ${objectsChanged} tile object(s).`);
        dialog.accept();
    });
    cancelBtn.clicked.connect(() => dialog.reject());

	dialog.exec();
});

action.text = "Mass Shift Tile References…";
action.iconVisibleInMenu = false;

// Add to Edit menu
tiled.extendMenu("Edit", [
    { action: "ShiftTileReferencesWithDialog" }
]);
