import std/private/osfiles
import std/private/osdirs
import std/strformat
import std/strutils
import std/sequtils
import std/random
import std/macros
import std/times
randomize()

type
  LogMessageType* = enum
    CRITICAL
    ERROR
    INFO
    DEBUG
  Log* = ref object
    ver  : string   # game version
    init : DateTime # initial timestamp for filename
    msgs : seq[tuple[msg: string, mtype: LogMessageType, time: DateTime]]

const LIMIT       = 5
const LOG_FORMAT  = "YYYY'_'MM'_'dd'__'hh'_'mm" # filename
const LOG_FORMAT2 = "YYYY'.'MM'.'dd' 'hh':'mm"  # cleaner txt format
const SYS_MSGS = [ # fun messages because Minecraft ones were cool (trying to combine OL's theme with idea of defeat (bug/crash) lol)
    "Reign wisely.",
    # CICERO
    "More is lost by indecision than wrong decision. Indecision is the thief of opportunity. It will steal you blind.",
    "It is not enough to acquire wisdom, it is necessary to employ it.",
    "Gratitude is not only the greatest of virtues, but the parent of all the others.",
    "It is the peculiar quality of a fool to perceive the faults of others and to forget his own.",
    # SUN TZU
    "In the midst of chaos, there is also opportunity.",
    "Victory is reserved for those who are willing to pay its price.",
    "If you are strong, appear weak. But if you are weak, appear strong.",
    "If a battle can not be won do not fight it.",
    "Correct your mistake as soon as you have found it."
]

proc purgeLogs () =
    # purges oldest logs, leaving only LIMIT count (considering alphabetical order, needs to walk files reversely)
    let logs = toSeq(walkFiles("logs/*.log"))
    let logc = len(logs)
    if logc >= LIMIT:
      for lg in logs[0..logc-LIMIT]:
          removeFile(lg)

proc initLog* (ver: string): Log =
    purgeLogs()
    new(result)
    result.ver  = ver
    result.init = now()

proc dumpLog* (l: Log, msg: string = "") =
    var contents : string
    add(contents, fmt"""[Of Lands' Log]
    {sample(SYS_MSGS)}
    --------------------------
    Version: {l.ver}
    Date:    {l.init.format(LOG_FORMAT2)}
    --------------------------
    """.unindent())
    for msg in l.msgs:
        # TODO: depending on mode, it should disable DEBUG and/or disable time stamps
        add(contents, fmt"{msg.time.format(LOG_FORMAT2)} [{$msg.mtype}] {msg.msg}" & "\n")
    if msg != "":
        add(contents, fmt"""A crash occured! Below is the detailed error message:
        {msg}
        """.unindent())
    writeFile(fmt"logs/{l.init.format(LOG_FORMAT)}.log", contents)
    discard

proc log* (l: Log, msg: string, mtype: LogMessageType = INFO) =
    add(l.msgs, (msg: msg, mtype: mtype, time: now()))

#=====================================
# SYNTAX SUGAR
#=====================================
proc `|`* (msg: string, mtype: LogMessageType): tuple[msg: string, mtype: LogMessageType] =
    return (msg, mtype)

proc `<-`* (l: Log, msg: string) =
    # alias | allows for `log <- "message"` syntax
    log(l, msg)

proc `<-`* (l: Log, m: tuple[msg: string, mtype: LogMessageType]) =
    # alias | allows for `log <- "message" | TYPE` syntax
    log(l, m.msg, m.mtype)

# macro `logBlock`* (l: static[Log], msg: static[string], cont_given: untyped): untyped =
#     #l <- msg # logging process | all else goes below:
#     var contents = newSeq[NimNode]() # block's contents
#     for c in cont_given:             # adds everything identated within block
#         add(contents, c)
#     # tribalify's chain of additions, translated into pure Nim due to not using tribalify here v
#     add(newStmtList(newSeq[NimNode]()), add(newBlockStmt(newNimNode(nnkEmpty)), newStmtList(contents)))