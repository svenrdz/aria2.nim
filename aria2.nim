import cppstl

export cppstl

const Header = "aria2.h"
{.passL: "libaria2.dylib".}

type
  CppPair*[T, U] {.importcpp: "std::pair<'0,'1>",
                   header: "<utility>".} = object
    first*: T
    second*: U
  KeyVals* {.importc: "aria2::KeyVals", header: Header.} =
    CppVector[CppPair[CppString, CppString]]
  A2Gid* = culonglong
  DownloadEvent* {.importcpp: "aria2::DownloadEvent", header: Header.} = enum
    deOnStart = 1
    deOnPause
    deOnStop
    deOnComplete
    deOnError
    deOnBtComplete
  SessionObj {.importc: "aria2::Session", header: Header.} = object
    context, listener: pointer
  Session* = ptr SessionObj
  DownloadEventCallback* {.importc: "aria2::DownloadEventCallback",
                           header: Header.} =
    proc (session: Session, event: DownloadEvent, gid: A2Gid,
          userData: pointer): cint {.cdecl.}
  SessionConfig* {.importc: "aria2::SessionConfig", header: Header.} = object
    keepRunning*, useSignalHandler*: bool
    downloadEventCallback*: DownloadEventCallback
    userData*: pointer
  RunMode* {.importc: "aria2::RUN_MODE", header: Header.} = enum
    rmDefault, rmOnce
  GlobalStat* {.importc: "aria2::GlobalStat", header: Header.} = object
    downloadSpeed*, uploadSpeed*: cint
    numActive*, numWaiting*, numStopped*: cint
  OffsetMode* {.importc: "aria2::OffsetMode", header: Header.} = enum
    omSet, omCur, omEnd
  UriStatus* {.importc: "aria2::UriStatus", header: Header.} = enum
    usUsed, usWaiting
  UriData* {.importc: "aria2::UriData", header: Header.} = object
    uri*: CppString
    status*: UriStatus
  FileData* {.importc: "aria2::FileData", header: Header.} = object
    index*: cint
    path*: CppString
    length*, completedLength*: int64
    selected*: bool
    uris*: CppVector[UriData]
  # BtFileMode* = enum
  #   bfmNone, bfmSingle, bfmMulti
  # BtMetaInfoData* = object
  #   announceList*: CppVector[CppVector[CppString]]
  #   comment*: CppString
  #   creationDate*: Time
  #   mode*: BtFileMode
  #   name*: CppString
  DownloadStatus* {.importc: "aria2::DownloadStatus", header: Header.} = enum
    dsActive, dsWaiting, dsPaused, dsComplete, dsError, dsRemoved
  DownloadHandle* = pointer

proc initKeyVals*(): KeyVals {.importcpp: "aria2::KeyVals", constructor.}

{.push dynlib: "libaria2.dylib", header: Header.}

proc libraryInit*: cint {.importc: "aria2::libraryInit".}
proc libraryDeinit*: cint {.importc: "aria2::libraryDeinit".}

proc newSession*(options: KeyVals, config: SessionConfig): Session
    {.importc: "aria2::sessionNew".}
proc sessionFinal*(session: Session): cint
    {.importc: "aria2::sessionFinal".}
proc run*(session: Session, mode: RunMode): cint
    {.importc: "aria2::run".}

proc hex*(gid: A2Gid): CppString
    {.importc: "aria2::gidToHex".}
proc gid*(hex: CppString): A2Gid
    {.importc: "aria2::hexToGid".}
proc isNull*(gid: A2Gid): bool
    {.importc: "aria2::isNull".}

proc addUri*(session: Session, gid: A2Gid,
            uris: CppVector[CppString],
            options: KeyVals,
            position: cint = -1): cint
    {.importc: "aria2::addUri".}
# proc addMetalink* ...
# proc addTorrent* ...

proc activeDownloads*(session: Session): CppVector[A2Gid]
    {.importc: "aria2::getActiveDownload".}
proc remove*(session: Session, gid: A2Gid, force: bool = false): cint
    {.importc: "aria2::removeDownload".}
proc pause*(session: Session, gid: A2Gid, force: bool = false): cint
    {.importc: "aria2::pauseDownload".}
proc unpause*(session: Session, gid: A2Gid): cint
    {.importc: "aria2::unpauseDownload".}

proc changeOption*(session: Session, gid: A2Gid, options: KeyVals): cint
    {.importc: "aria2::changeOption".}
proc getGlobalOption*(session: Session, name: CppString): CppString
    {.importc: "aria2::getGlobalOption".}
proc getGlobalOptions*(session: Session): KeyVals
    {.importc: "aria2::getGlobalOptions".}
proc changeGlobalOption*(session: Session, options: KeyVals): cint
    {.importc: "aria2::changeGlobalOption".}

proc stats*(session: Session): GlobalStat
    {.importc: "aria2::getGlobalStat".}

proc changePosition*(session: Session, gid: A2Gid,
                     pos: cint, how: OffsetMode): cint
    {.importc: "aria2::changePosition".}

proc shutdown*(session: Session, force: bool = false): cint
    {.importc: "aria2::shutdown".}

{.pop.}

## DownloadHandle interface

const reinterpret = "reinterpret_cast<aria2::DownloadHandle*>"

proc `[]`*(session: Session, gid: A2Gid): DownloadHandle =
  {.emit: "result = reinterpret_cast<`DownloadHandle`>(aria2::getDownloadHandle(session, gid));".}
proc delete*(handle: DownloadHandle) =
  {.emit: "delete " & reinterpret & "(`handle`);".}

proc status*(handle: DownloadHandle): DownloadStatus =
  {.emit: "result = " & reinterpret & "(`handle`)->getStatus();".}
proc len*(handle: DownloadHandle): int64 =
  {.emit: "result = " & reinterpret & "(`handle`)->getTotalLength();".}
proc completedLen*(handle: DownloadHandle): int64 =
  {.emit: "result = " & reinterpret & "(`handle`)->getCompletedLength();".}
proc uploadLen*(handle: DownloadHandle): int64 =
  {.emit: "result = " & reinterpret & "(`handle`)->getUploadLength();".}

proc bitfield*(handle: DownloadHandle): CppString =
  {.emit: "result = " & reinterpret & "(`handle`)->getBitfield();".}
proc infoHash*(handle: DownloadHandle): CppString =
  {.emit: "result = " & reinterpret & "(`handle`)->getInfoHash();".}

proc downloadSpeed*(handle: DownloadHandle): int64 =
  {.emit: "result = " & reinterpret & "(`handle`)->getDownloadSpeed();".}
proc uploadSpeed*(handle: DownloadHandle): int64 =
  {.emit: "result = " & reinterpret & "(`handle`)->getUploadSpeed();".}

proc pieceLen*(handle: DownloadHandle): int64 =
  {.emit: "result = " & reinterpret & "(`handle`)->getPieceLength();".}
proc numPieces*(handle: DownloadHandle): cint =
  {.emit: "result = " & reinterpret & "(`handle`)->getNumPieces();".}
proc connections*(handle: DownloadHandle): cint =
  {.emit: "result = " & reinterpret & "(`handle`)->getConnections();".}
proc errorCode*(handle: DownloadHandle): cint =
  {.emit: "result = " & reinterpret & "(`handle`)->getErrorCode();".}

proc followedBy*(handle: DownloadHandle): CppVector[A2Gid] =
  {.emit: "result = " & reinterpret & "(`handle`)->getFollowedBy();".}
proc following*(handle: DownloadHandle): A2Gid =
  {.emit: "result = " & reinterpret & "(`handle`)->getFollowing();".}
proc belongsTo*(handle: DownloadHandle): A2Gid =
  {.emit: "result = " & reinterpret & "(`handle`)->getBelongsTo();".}

proc dir*(handle: DownloadHandle): CppString =
  {.emit: "result = " & reinterpret & "(`handle`)->getDir();".}
proc files*(handle: DownloadHandle): CppVector[FileData] =
  {.emit: "result = " & reinterpret & "(`handle`)->getFiles();".}
proc numFiles*(handle: DownloadHandle): cint =
  {.emit: "result = " & reinterpret & "(`handle`)->getNumFiles();".}
proc file*(handle: DownloadHandle, index: cint): FileData =
  {.emit: "result = " & reinterpret & "(`handle`)->getFile(`index`);".}

proc option*(handle: DownloadHandle, name: CppString): CppString =
  {.emit: "result = " & reinterpret & "(`handle`)->getOption(`name`);".}
proc options*(handle: DownloadHandle): KeyVals =
  {.emit: "result = " & reinterpret & "(`handle`)->getOptions();".}

when isMainModule:
  import std/os

  echo libraryInit()
  sleep 2000
  echo libraryDeinit()
