### MODULE THAT SHOULD HAVE ALL PARSING
#################################################
# FILES
# Module for all parsing
#################################################
import std/strformat
import std/strutils
import parsetoml
import resources
import logging

var MAP_GEN* = -1 # var used for resource draining (`addResources` procs)

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

proc parseCountRange* (cr: string): tuple[low, high: int] =
    let crp = cr.split("-")
    case len(crp):
      of 1: return (parseInt(crp[0].strip()), parseInt(crp[0].strip()))
      of 2: return (parseInt(crp[0].strip()), parseInt(crp[1].strip()))
      else: log |: fmt"Incorrect count range: {cr}"; return (0, 0)

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
                                     name  = olr["resource"][res_id]["name"].getStr(""),
                                     index = ix,
                                     qual  = olr["resource"][res_id]["quality"].getInt(0),
                                     fuel  = olr["resource"][res_id]["fuel"].getInt(0)
                                     )

#################################################
# FACTIONS
#################################################
proc getFactionFile* (olm: TomlValueRef): string =
    if olm.hasKey("factions"):
        return olm["factions"].getStr()
    return "" # aka "no file provided, start with only player"