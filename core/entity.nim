type
  EntityRole* = enum # numbers represent tile index in system tileset
    SETTLER = 0
  Entity* = ref object
    role* : EntityRole
    knb*  : int        # kingdom number
    # potentially Tile? so it's backtracked, *but* be mindful of circular imports

proc newEntity* (role: EntityRole, knb: int): Entity =
    # ideally shouldn't be a public one, because its general destination should be use within `addEntity` context (to ensure it's added to both Tile and Kingdom)
    # todo: may be redundant??? depending on how much circularity it will have eventually making `addEntity` doing this not feasible
    new(result)
    result.role = role
    result.knb  = knb