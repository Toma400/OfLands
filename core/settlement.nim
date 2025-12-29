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
    res*     : Table[string, int] # resources stored (resource ID, amount)
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