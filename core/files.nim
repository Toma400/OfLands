### MODULE THAT SHOULD HAVE ALL PARSING
#################################################
# FILES
# Module for all parsing
#################################################
import std/strformat
import parsetoml
import resources

proc parseDate* (olm: TomlValueRef): tuple[year, month, day, hour: int] =
    if olm.hasKey("start_date"):
        let dates = olm["start_date"].getElems()
        if len(dates) >= 3:
            return (year: dates[0].getInt(), month: dates[1].getInt(), day: dates[2].getInt(), hour: 1)
        elif len(dates) == 2:
            return (year: dates[0].getInt(), month: dates[1].getInt(), day: 1,                 hour: 1)
        elif len(dates) == 1:
            return (year: dates[0].getInt(), month: 1,                 day: 1,                 hour: 1)
    return (year: 1, month: 1, day: 1, hour: 1)

proc parseResourcesFile* (olr_path: string): OrderedTable[string, Resource] =
    let olr = parseFile(fmt"maps/{olr_path}") # gets TomlValueRef
    if existsKey(olr, "resource"):
        for res_id in olr["resource"].getTable.keys():
            result[res_id] = newResource(
                                         name  = olr["resource"][res_id]["name"].getStr(),
                                         index = olr["resource"][res_id]["index"].getInt(),
                                         qual  = olr["resource"][res_id]["quality"].getInt(0),
                                         fuel  = olr["resource"][res_id]["fuel"].getInt(0)
                                         )