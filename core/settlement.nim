import std/strformat
import std/tables
import std/random
import resources
randomize()

type
  SettlementTier* = enum
    VILLAGE = 0
    TOWN    = 1
    CITY    = 2
    POLIS   = 3
    # special types
    TENT    = 4
    CASTLE  = 5
  SettlementTile* = ref object # Tile variation that covers data of particular tile
    settlem* : Settlement
    coords*  : tuple[x, y: int]
    res*     : Table[int, int]  # resources stored (resource ID, amount)
    res_wgt* : int              # resources' weight (for easy access, overridden when res added/removed)
  Settlement* = ref object
    name*  : string
    tier*  : SettlementTier
    tiles* : seq[SettlementTile]
    owner* : int

const TIER_STR* = { # string representation for .olf parsing
    "camp":    TENT,   # alias
    "tent":    TENT,
    "fort":    CASTLE, # alias
    "castle":  CASTLE,
    "village": VILLAGE,
    "town":    TOWN,
    "city":    CITY,
    "polis":   POLIS
}.toTable

proc `$`* (s: Settlement): string =
    result = fmt"{s.name} | Tier: {s.tier} | Kingdom index: {s.owner}"

proc generateRandomName* (): string =
    const B = ["La", "Ni", "Te", "Ku", "Me", "Su", "Hag"]
    const M = ["hele", "una", "mino", "tere", "siva", "lini", "ta", "inu"]
    const E = ["let", "sot", "rut", "kif", "anna", "un", "be", "far"]
    result = sample(B) & sample(M) & sample(E)

proc newSettlementTile* (coords: tuple[x, y: int]): SettlementTile =
    # always use with `newSettlement`, else the tile will not be valid (settlem = None)
    new(result)
    result.coords = coords
    # defaults:
    # res     = newTable[int, int]()
    # res_wgt = 0

proc newSettlement* (name: string, init_tiles: seq[SettlementTile], kingdom: int, tier: SettlementTier = VILLAGE): Settlement =
    # helper proc, should not be used by itself (you need to assign settlement to kingdom)
    # todo: use `addSettlement` from either `map.nim` or `game.nim` depending on need
    new(result)
    result.name  = name
    result.tier  = tier
    result.owner = kingdom
    for tile in init_tiles:
        tile.settlem = result # autoreference binding
        result.tiles.add(tile)

proc storageCap* (st: SettlementTile): int =
    case st.settlem.tier:
      of VILLAGE: result += 20
      of TOWN:    result += 30
      of CITY:    result += 50
      of POLIS:   result += 75
      of TENT:    result += 10
      of CASTLE:  result += 25

proc addResourceCheck* (st: SettlementTile, res: Resource): bool =
    let sc = storageCap(st)
    let sw = st.res_wgt
    let rw = res.weight
    if res.index notin st.res: # avoids null pointing
        st.res[res.index] = 0
    return sw + rw <= sc

proc addResource* (st: SettlementTile, res: Resource, src: var int) =
    # st  : SettlementTile | settlement the resource is added to
    # res : Resource       | resource added
    # src : _var_ int      | source to be substracted from
    if src > 0 or src < 0: # below 0 means map gen
      if addResourceCheck(st, res):
          src               -= 1
          st.res[res.index] += 1
          st.res_wgt += res.weight # adds weight of the resource

proc addResources* (st: SettlementTile, res: Resource, src: var int, am: int) =
    # st  : SettlementTile | settlement the resource is added to
    # res : Resource       | resource added
    # src : _var_ int      | source to be substracted from
    # am  :       int      | amount of resource (iterative)
    for _ in 1..am:
      addResource(st, res, src)