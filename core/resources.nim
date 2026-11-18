import std/tables
import settlement
import location

type
  ResourceKind = enum
    COIN
    # building resources
    WOOD
    CLAY
    STONE
    # food
    FISH
    MEAT
    WHEAT
    BEER
    WINE
    TEA
    SALT      # : used to decrease food usage
    SUGAR     # : used to decrease food usage
    SPICES    # : used to decrease food usage (exclusive)
    # utility
    IRON
    GOLD
    COPPER
    BRICKS
    WOOL
    COAL      # : used for cheaper heating
    POTTERY
    FURNITURE
    CLOTHING
    TOOLS
    WEAPONS
    # exclusive  | important for late game, improve citizens' morale
    SILK
    JEWELRY

  Resource* = ref object # ref bc used for comparison in inventories/storages (only one instance in map.data.rdefs)
    name*   : string       # visible name
    index*  : int          # tile int (for rendering)
    weight* : int          # used to calculate taken size vs tile storage cap
    #kind*  : ResourceKind
    qual*   : int          # quality value | if not applicable, value of 0 is used (default)
    fuel*   : int          # fuel value    | non-fuels should just have value of 0 (default)

proc newResource* (name: string, index: int, weight, qual, fuel: int): Resource =
    new(result)
    result.name   = name
    result.index  = index
    result.weight = weight
    result.qual   = qual
    result.fuel   = fuel

#[ requires `ref object` to get rid of `var` ]#
proc addResourceCheck* (lc: Location, res: Resource): bool =
    let lw = lc.res_wgt
    let rw = res.weight
    if res.index notin lc.res: # avoids null pointing
        lc.res[res.index] = 0
    return lw + rw <= lc.res_cap

proc addResourceCheck* (st: SettlementTile, res: Resource): bool =
    let sc = storageCap(st)
    let sw = st.res_wgt
    let rw = res.weight
    if res.index notin st.res: # avoids null pointing
        st.res[res.index] = 0
    return sw + rw <= sc

proc addResource* (to: SettlementTile | Location, res: Resource, src: var int) =
    # to  : SettlementTile/Location | object the resource is added to
    # res : Resource                | resource added
    # src : _var_ int               | source to be substracted from
    if src > 0 or src < 0: # below 0 means map gen
      if addResourceCheck(to, res):
          src               -= 1
          to.res[res.index] += 1
          to.res_wgt += res.weight # adds weight of the resource

proc addResources* (to: SettlementTile | Location, res: Resource, src: var int, am: int) =
    # to  : SettlementTile/Location | object the resource is added to
    # res : Resource                | resource added
    # src : _var_ int               | source to be substracted from
    # am  :       int               | amount of resource (iterative)
    for _ in 1..am:
      addResource(to, res, src)

# List of resources for PTR map:
#[
  - base
    - septim (coin)
  - buildings
    - wood
    - clay  -> bricks
    - stone

# idea: settlements' limits would force you to make multiple settlement, each producing goods?
#       this way village A would need to help village B to reach town tier, and village B would
#       also exchange its unique resources to village A helping it in return
# (e.g. if village is up to 2 tiles, and you can't afford making [woodworker, inn, brickmason, church, market, smith]
#       buildings, you can spread those into two villages where A would have woodworker, B would have
#       brickmason, and they'd exchange those resources simply) ]#