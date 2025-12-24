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

  Resource* = ref object # todo: ref??? just so you can do comparison for inventories/tables I guess
    kind* : ResourceKind
    qual* : int          # quality value | if not applicable, value of 0 is used (default)
    fuel* : int          # fuel value    | non-fuels should just have value of 0 (default)

proc newResource* (k: ResourceKind, fuel: int = 0): Resource =
    result.kind = k
    result.fuel = fuel

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
#       brickmason, and they'd exchange those resources simply)