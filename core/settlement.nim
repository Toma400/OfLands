import std/random
randomize()

type
  SettlementTier* = enum
    VILLAGE = 0
    TOWN    = 1
    CITY    = 2
    POLIS   = 3
  SettlementTile* = ref object # Tile variation that covers data of particular tile
    settlem* : Settlement
    coords*  : tuple[x, y: int]
  Settlement* = ref object
    name*  : string
    tier*  : SettlementTier
    tiles* : seq[SettlementTile]
    knb*   : int

proc generateRandomName* (): string =
    const B = ["La", "Ni", "Te", "Ku", "Me"]
    const M = ["hele", "una", "mino", "tere", "siva", "lini"]
    const E = ["let", "sot", "rut", "kif", "anna", "un"]
    result = sample(B) & sample(M) & sample(E)

proc newSettlementTile* (coords: tuple[x, y: int]): SettlementTile =
    # always use with `newSettlement`, else the tile will not be valid (settlem = None)
    new(result)
    result.coords = coords

proc newSettlement* (name: string, init_tiles: seq[SettlementTile], kingdom: int, tier: SettlementTier = VILLAGE): Settlement =
    # helper proc, should not be used by itself (you need to assign settlement to kingdom)
    # todo: kingdom assignment, but also initial Tile assignment (or at least coords if Tile wouldn't be available)
    new(result)
    result.name = name
    result.tier = tier
    result.knb  = kingdom
    for tile in init_tiles:
        tile.settlem = result # autoreference binding
        result.tiles.add(tile)