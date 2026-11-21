### MODULE THAT SHOULD HAVE ALL PARSING
#################################################
# FILES
# Module for all parsing
#################################################
import std/strformat
import std/strutils
import parsetoml
import resources
import location
import logging
import common
import ../map

const START_HOUR = 10 # game starts at daytime

var MAP_GEN*  = -1 # var used for resource draining (`addResources` procs)

proc parseDate* (olm: TomlValueRef): tuple[year, month, day, hour: int] =
    if olm.hasKey("start_date"):
        let dates = olm["start_date"].getElems()
        if len(dates) >= 3:
            return (year: dates[0].getInt(), month: dates[1].getInt(), day: dates[2].getInt(), hour: START_HOUR)
        elif len(dates) == 2:
            return (year: dates[0].getInt(), month: dates[1].getInt(), day: 1,                 hour: START_HOUR)
        elif len(dates) == 1:
            return (year: dates[0].getInt(), month: 1,                 day: 1,                 hour: START_HOUR)
    return (year: 1, month: 1, day: 1, hour: START_HOUR)

proc parseCountRange* (cr: string): tuple[low, high: int] =
    let crp = cr.split("-")
    case len(crp):
      of 1: return (parseInt(crp[0].strip()), parseInt(crp[0].strip()))
      of 2: return (parseInt(crp[0].strip()), parseInt(crp[1].strip()))
      else: log |: fmt"Incorrect count range: {cr}"; return (0, 0)

#################################################
# FILES
#################################################
proc parseTerrainOLDATA* (oldata_file: string): OrderedTable[int, TilePrefab] =
    # parses .oldata file and returns tile definitions in an OrderedTable
    log |: fmt"Parsing terrain file: {oldata_file}"
    let oldata = parseFile(fmt"tilesets/{oldata_file}")
    for cat in oldata.getTable.keys():
        if cat == "tile":
            for tile_key in oldata["tile"].getTable.keys():
                log |: fmt"Analysing tile: {tile_key}" # TODO: should be DEBUG type
                # optional values
                let winter_ix = if "winter_tile"    in oldata["tile"][tile_key]: oldata["tile"][tile_key]["winter_tile"].getInt()    else: -1
                let winter_mv = if "winter_mv_cost" in oldata["tile"][tile_key]: oldata["tile"][tile_key]["winter_mv_cost"].getInt() else: -1
                let tl_name   = if "name"           in oldata["tile"][tile_key]: oldata["tile"][tile_key]["name"].getStr()           else: ""
                # initialises prefab, using default values if key not found
                result[parseInt(tile_key)] = newTilePrefab(
                                                           tname   = tl_name,
                                                           mv_cost = oldata["tile"][tile_key]["mv_cost"].getInt(),
                                                           tbase   = oldata["tile"][tile_key]["tbase"].getStr(),
                                                           w_ix    = winter_ix,
                                                           w_mv    = winter_mv,
                                                           #road_ac = (false, false, false, false)         # TODO | temporary
                                                           )

#################################################
# RESOURCES
#################################################
proc parseResourcesFile* (olr_path: string): OrderedTable[int, Resource] =
    log |: fmt"Parsing resource file: {olr_path}"
    let olr = parseFile(fmt"maps/{olr_path}") # gets TomlValueRef
    if existsKey(olr, "resource"):
        for res_id in olr["resource"].getTable.keys():
            log |: fmt"Analysing resource: {res_id}" # TODO: should be DEBUG type
            let ix = parseInt(res_id)
            result[ix] = newResource(
                                     name   = olr["resource"][res_id]["name"].getStr(""),   # REQUIRED (in practice optional)
                                     index  = ix,
                                     weight = olr["resource"][res_id]["weight"].getInt(),   # REQUIRED
                                     qual   = olr["resource"][res_id]["quality"].getInt(0), # OPTIONAL
                                     fuel   = olr["resource"][res_id]["fuel"].getInt(0)     # OPTIONAL
                                     )

#################################################
# LOCATIONS
#################################################
proc parseLocationOLDATA* (oldata_file: string): OrderedTable[int, LocationPrefab] =
    # parses .oldata file and returns tile definitions in an OrderedTable
    log |: fmt"Parsing location .oldata file..."
    let oldata = parseFile(fmt"tilesets/{oldata_file}")
    for cat in oldata.getTable.keys():
        if cat == "tile":
            for tile_key in oldata["tile"].getTable.keys():
                # optional values
                let lc_scap = if "storage_size" in oldata["tile"][tile_key]: oldata["tile"][tile_key]["storage_size"].getInt() else: 0
                # not optional value, but useful for debugging
                let lc_name = if "name"         in oldata["tile"][tile_key]: oldata["tile"][tile_key]["name"].getStr()         else: ""

                var lc_loot : OrderedTable[int, tuple[low, high: int]]
                if "storage" in oldata["tile"][tile_key]:
                    log |: fmt"Parsing loot table for location: {tile_key} ({lc_name})..."
                    for res_id, res_val in oldata["tile"][tile_key]["storage"].getTable():
                        lc_loot[parseInt(res_id)] = parseCountRange(res_val.getStr())

                var lc_prod : Production
                if "production" in oldata["tile"][tile_key]:
                    log |: fmt"Parsing production table for location: {tile_key} ({lc_name})..."
                    for prod_id, prod_data in oldata["tile"][tile_key]["production"].getTable():
                        let prod_id_parsed = parseInt(prod_id.split(" | ")[0])
                        let prod_data_seq  = getElems(prod_data)
                        lc_prod[prod_id_parsed] = (res   : prod_data_seq[0].getInt(), # resource ID
                                                   turns : prod_data_seq[1].getInt(), # turns needed to produce
                                                   count : prod_data_seq[2].getInt()) # resource count produced
                # initialises prefab, using default values if key not found
                result[parseInt(tile_key)] = newLocationPrefab(
                                                               lname   = oldata["tile"][tile_key]["name"].getStr(),
                                                               bcond   = oldata["tile"][tile_key]["bcond"].getStr(),
                                                               res_cap = lc_scap,
                                                               loot    = lc_loot,
                                                               prod    = lc_prod,
                                                               )

#################################################
# FACTIONS
#################################################
proc getFactionFile* (olm: TomlValueRef): string =
    if olm.hasKey("factions"):
        return olm["factions"].getStr()
    return "" # aka "no file provided, start with only player"