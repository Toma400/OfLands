import std/xmlparser
import std/xmltree
import std/tables
import std/strtabs
import std/strformat
import std/strutils
import questionable
import parsetoml

type
  # MapProperties = object
  #   compatibility  : string #?
  #   factions_count : ?int
  #   start_coords   : ?string
  #   start_date     : ?string
    # "factions_count" #? how to get OLM files to work with it
    # "start_coords" # OPTIONAL
    # "start_date" # OPTIONAL
  IntermediateMap = object
    size: tuple[width, height: int]
    properties: tuple[
        #factions_count : ?int
        start_coords : string, # "" if no field in OLM/TMX file
        start_date   : string, # "" if no field in OLM/TMX file
    ]
    name : string
    # tileset_images : tuple[
    #     terrain,
    #     locations,
    #     resources,
    #     factions,
    #     system
    #     : string # type
    # ]
  FileType = enum
    TMXfile # Tiled's map file
    TSXfile # Tiled's tileset file
    # Of Lands' files here

const
  DEFAULT_PATH = "tiled/"
  # CORRECT_VALS : Table[FileType, tuple[setting, val: string]]= { # used to verify TMX/TSX/OLM files *and* provide correct data for new one
  #     TMXfile = (
  #       "orientation": "orthogonal",
  #       "renderorder": "right-down",
  #       "tilewidth": "32",
  #       "tileheight": "32",
  #       "infinite": "0"
  #     )
  # }

proc getStrFromElem(toml_elem: TomlValueRef): string =
    # empty elem returns ""
    for entry in toml_elem.getElems():
        result = result & $entry.getInt() & ", "
    if len(result) > 1:
      if result[^2..^1] == ", ": result[^2..^1] = "" # cuts the last `, `

proc parseOLM (file: string) : IntermediateMap =
    let OLMFile = parseFile(file)
    result.properties = (
        start_coords : OLMFile["start_coordinates"].getStrFromElem(),
        start_date   : OLMFile["start_date"].getStrFromElem()
    )
    # result.tileset_images = (
    #     terrain   : OLMFile["tileset_terrain"].getStr(),
    #     locations : OLMFile["tileset_locations"].getStr(),
    #     resources : OLMFile["tileset_resources"].getStr(),
    #     factions  : OLMFile["tileset_factions"].getStr(),
    #     system    : OLMFile["tileset_system"].getStr(),
    # )
    result.name = "_" # TODO!!!! it's name of the file??
    result.size = ( # TODO: needs error handling if empty
        width  : len(OLMFile["terrain"].getElems()[0]),
        height : len(OLMFile["terrain"].getElems())
    )

proc parseTMX (file: string) : IntermediateMap =
    let xmlFile = loadXML(file)
    var map_properties : XmlNode
    var tileset_files  : seq[XmlNode]
    var layers         : seq[XmlNode]
    for mdata in xmlFile.items():
      case tag(mdata):
        of "properties": map_properties = mdata
        of "tileset":    add(tileset_files, mdata)
        of "layer":      add(layers, mdata)
        # "imagelayer" skipped, junk data?

    for property in map_properties.items():
      case attr(property, "name"):
        of "start_coords": result.properties.start_coords = attr(property, "value") # evaluates to "" if tag doesn't exist/empty/no 'value' attr
        of "start_date":   result.properties.start_date   = attr(property, "value") # evaluates to "" if tag doesn't exist/empty/no 'value' attr
    result.name = "_" # TODO!!!! it's name of the file??
    result.size = (
        width  : parseInt(attr(xmlFile, "width")),
        height : parseInt(attr(xmlFile, "height"))
    )

    # echo xmlFile
    # echo "----"
    # echo tag(xmlFile) == "map"
    # echo attr(xmlFile, "orientation")
    # for i, v in attrs(xmlFile):
    #     echo i & ":" & v
    # echo "width" in attrs(xmlFile)

    # let xmlMain = tag(xmlMain) == "map"
    # let xmlMainAttrs = xmlMain.attrs # nextlayerid="14" nextobjectid="4"?????
    # things for emptyProject:
      # - orientation="orthogonal"
      # - renderorder="right-down"
      # - tilewidth="32"
      # - tileheight="32"
      # - infinite="0"

proc exportOLM (imap: IntermediateMap) =
    discard

proc exportTMX (imap: IntermediateMap) =
    discard

proc newProject (): IntermediateMap =
    discard

#### TEMPORARY QUICK CONVERTING ####
let til_map = parseTMX("../maps/tamriel.tmx")
let ol_map  = parseOLM("../maps/tamriel.olm")

echo til_map.size == ol_map.size
echo ol_map.size