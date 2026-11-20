import std/tables
#################################################
# COMMON
# Module for shared types, utility procs etc.
#################################################

type
  # aliases for shared data types
  Production* = seq[tuple[res, turns, count: int]] # used to determine (current, simplified) resource rate
  ResStorage* = OrderedTable[int, int]             # resource storage used by Location and SettlementTile