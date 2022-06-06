import std/[os, times], aria2

# var cerr = echo
# template cerr(args: untyped) =
#   echo args
#   echo msg

const endl = "\n"

proc cerr(msg: varargs[string, `$`]) =
  for m in msg:
    stderr.write m
  flushFile stderr

proc downloadEventCallback(session: Session,
                           event: DownloadEvent,
                           gid: A2Gid,
                           userData: pointer): cint {.cdecl.} =
  case event
  of deOnComplete:
    cerr "Complete"
  of deOnError:
    cerr "Error"
  else:
    return 0
  cerr(" [", gid.hex, "]")
  let dh = session[gid]
  if dh.numFiles > 0:
    let f = dh.file(1)
    if f.path.empty:
      if f.uris.empty:
        cerr f.uris[0].uri
    else:
      cerr f.path
  cerr endl
  delete dh
  return 0

proc main: cint =
  discard libraryInit()

  var
    session: Session
    config: SessionConfig
    options = initKeyVals()
  config.downloadEventCallback = downloadEventCallback
  session = newSession(options, config)
  for i in 1 .. paramCount():
    let
      uri = initCppString(paramStr(i))
      uris = initCppVector(1, uri)
    result = session.addUri(0, uris, options)
    if result < 0:
      cerr("Failed to add download ", uri, endl)

  var start = cpuTime()
  while true:
    result = session.run rmOnce
    if result != 1:
      break
    let
      now = cpuTime()
    if now - start > 0.05:
      start = now
      let stats = session.stats
      cerr("Overall #Active:", stats.numActive,
           " #waiting:", stats.numWaiting,
           " D:", stats.downloadSpeed.int shr 20, " MiB/s",
           " U:", stats.uploadSpeed.int shr 20, " MiB/s", endl)
      for gid in session.activeDownloads():
        let dh = session[gid]
        if dh != nil:
          let
            len = dh.len.int shr 20
            completed = dh.completedLen.int shr 20
            percent =
              if len > 0: int(100 * completed / len)
              else: 0
            dSpeed = dh.downloadSpeed.int shr 20
            uSpeed = dh.uploadSpeed.int shr 20
          cerr("    [", gid.hex, "] ",
               completed, "/", len,
               "(", percent, "%)",
               " D:", dSpeed, " MiB/s",
               " U:", uSpeed, " MiB/s", endl)
          delete dh

  result = session.sessionFinal()
  discard libraryDeinit()

when isMainModule:
  quit(main())
