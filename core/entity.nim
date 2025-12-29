import resources

type
  EntityRole* = enum # numbers represent tile index in system tileset
    SETTLER = 0
    SHIP    = 10 # todo: temporary?
  Entity* = ref object
    role*   : EntityRole
    res*    : Table[string, int] # resources stored (resource ID, amount)
    owner*  : int                # kingdom number
    mov_rg  : int                # movement points regained each turn
    mov_pt* : int                # movement points reference has
    # potentially Tile? so it's backtracked, *but* be mindful of circular imports

const
  #AIR_ENTITY*   = []
  LAND_ENTITY*  = [SETTLER]
  WATER_ENTITY* = [SHIP]

proc getSpeed(er: EntityRole): int =
    const DEF_SPEED = 15
    # returns speed regain points (15 is default for most entities)
    case er:
      of SETTLER: return DEF_SPEED
      of SHIP:    return 30

proc newEntity* (role: EntityRole, knb: int): Entity =
    # ideally shouldn't be a public one, because its general destination should be use within `addEntity` context (to ensure it's added to both Tile and Kingdom)
    # todo: may be redundant??? depending on how much circularity it will have eventually making `addEntity` doing this not feasible
    new(result)
    result.role   = role
    result.owner  = knb
    result.mov_rg = getSpeed(role)
    result.mov_pt = 0              # starting from 0, each turn should set it to `mov_rg` (except if it's during movement to tile that exceeds limit)