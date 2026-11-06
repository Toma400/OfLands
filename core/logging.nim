import std/private/osfiles
import std/private/osdirs
import std/strformat
import std/strutils
import std/sequtils
import std/random
import std/macros
import std/times
import system
randomize()

type
  LogMessageType* = enum
    CRITICAL
    ERROR
    INFO
    DEBUG
  Log* = ref object
    init : DateTime # initial timestamp for filename
    msgs : seq[tuple[msg: string, mtype: LogMessageType, time: DateTime]]

const LIMIT       = 5
const LOG_FORMAT  = "YYYY'_'MM'_'dd'__'HH'_'mm"      # filename
const LOG_FORMAT2 = "YYYY'.'MM'.'dd' 'HH':'mm':'ss"  # cleaner txt format
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

proc initLog* (): Log =
    purgeLogs()
    new(result)
    result.init = now()

proc dumpLog* (l: Log, msg: string = "") =
    var contents : string
    add(contents, fmt"""[Of Lands' Log]
    {sample(SYS_MSGS)}
    --------------------------
    Version: {GAME_VER}
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

proc logMsg (l: Log, msg: string, mtype: LogMessageType = INFO) =
    add(l.msgs, (msg: msg, mtype: mtype, time: now()))

var log* = initLog()

#=====================================
# SYNTAX SUGAR
#=====================================
proc `|`* (msg: string, mtype: LogMessageType): tuple[msg: string, mtype: LogMessageType] =
    return (msg, mtype)

# proc `>`* (t1, t2: tuple[msg: string, mtype: LogMessageType]): tuple[msg_start: string, mtype1: LogMessageType,
#                                                                      msg_end: string,   mtype2: LogMessageType] =
#     return (t1.msg, t1.mtype, t2.msg, t2.mtype)

proc `|:`* (l: Log, msg: string) =
    # alias | allows for `log |: "message"` syntax (of default INFO type)
    logMsg(l, msg)

# proc `|:`* (l: Log, m: tuple[msg: string, mtype: LogMessageType]) =
#     # alias | allows for `log |: "message" | TYPE` syntax
#     logMsg(l, m.msg, m.mtype)

template `|>`* (l: Log, msg: string, process: untyped) =
    # starts block while prompting logging process at the start (of default INFO type)
    # `log |> str:`
    l |: msg
    process

# TODO: below doesn't work for some reason
# template `|>`* (l: Log, m: tuple[msg: string, mtype: LogMessageType], process: untyped) =
#     # starts block while prompting logging process at the start
#     # `log |> str | TYPE:`
#     l |: m.msg | m.mtype
#     process
#
# template process* (l: Log, m: tuple[msg_start: string, mtype1: LogMessageType, msg_end: string, mtype2: LogMessageType], process: untyped) =
#     # starts block while prompting logging process at the start and end
#     # `log.process |: str1 | TYPE1 > str2 | TYPE2:`
#     l |: m.msg_start | m.mtype1
#     process
#     l |: m.msg_end | m.mtype2