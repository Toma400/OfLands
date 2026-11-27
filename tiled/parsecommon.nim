##########################################
# PARSECOMMON
# Exporter's shared objects/procs
##########################################

type
  IntermediateMap* = object
    name*: string
    size*: tuple[width, height: int]
    properties*: tuple[
        #factions_count : ?int
        start_coords : string, # "" if no field in OLM/TMX file
        start_date   : string, # "" if no field in OLM/TMX file
    ]