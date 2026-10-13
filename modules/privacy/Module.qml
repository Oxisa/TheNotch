import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Commons
import "../.."

// Privacy: who is using the microphone and the camera. The collapsed notch
// shows an orange mic / green camera dot (like macOS); hovering it lists the
// apps. Settings → Privacy keeps a log. It only shows — it doesn't block.
NotchModule {
  id: pv
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Конфиденциальность", "Privacy")
  icon: "\u{f0565}"
  description: t("Кто сейчас пользуется микрофоном и камерой", "Who is using the microphone and the camera")
  inRail: false
  settingsSection: "privacy"
  sectionOrder: 0
  settingsPage: Component { PrivacySettings { mod: pv } }
  peek: Component { PrivacyPeek { mod: pv } }
  peekWidth: 320
  function opt(key, fallback) { return notch ? notch.moduleOpt("privacy", key, fallback) : fallback }
  function persist(values) { if (notch) notch.modulePersist("privacy", values) }

  readonly property color micColor: "#ff9f0a"
  readonly property color camColor: "#30d158"
  readonly property bool showDots: opt("dots", true) !== false
  readonly property bool announce: opt("announce", true) !== false

  property bool primed: false              // no message for apps already on at start
  property var mic: []
  property var cam: []
  readonly property bool inUse: active && (mic.length > 0 || cam.length > 0)
  readonly property string bin: decodeURIComponent(Qt.resolvedUrl("bin/privctl").toString().replace(/^file:\/\//, ""))

  // ---- the microphone and portal cameras: straight from PipeWire, by events
  // (polling pw-dump every 2 s cost ~16 % of a core). A capture stream fed by
  // a real source (not a speaker's monitor — visualizers listen to those).
  readonly property var streams: Pipewire.nodes ? Pipewire.nodes.values.filter(function(n) { return n && n.isStream }) : []
  PwObjectTracker { objects: pv.streams }
  function appOf(n) {
    var p = n.properties || {}
    return { app: String(p["application.name"] || n.name || "?"), bin: String(p["application.process.binary"] || ""), pid: Number(p["application.process.id"] || 0) }
  }
  readonly property var micNow: {
    var gs = Pipewire.linkGroups ? Pipewire.linkGroups.values : [], seen = {}, out = []
    for (var i = 0; i < gs.length; i++) {
      var g = gs[i], s = g.source, t = g.target
      if (!s || !t) continue                                        // (link state reads -1 untracked; a link existing is enough)
      if (!t.isStream || s.isStream || s.isSink) continue           // a real (or virtual) microphone → a recording stream
      if (String(t.name || "").indexOf("soundhub_") === 0) continue
      var a = appOf(t)
      if (!seen[a.app]) { seen[a.app] = 1; out.push(a) }
    }
    return out
  }
  readonly property var portalCams: streams.filter(function(n) { return String((n.properties || {})["media.class"] || "") === "Stream/Input/Video" }).map(appOf)
  property var deviceCams: []
  readonly property var camNow: { var seen = {}, out = []; deviceCams.concat(portalCams).forEach(function(a) { if (!seen[a.app]) { seen[a.app] = 1; out.push(a) } }); return out }
  onMicNowChanged: settle.restart()
  onCamNowChanged: settle.restart()
  // a short wait so a stream that blinks on and off doesn't flash the notch
  Timer { id: settle; interval: 400; onTriggered: { pv.update("mic", pv.micNow); pv.update("cam", pv.camNow); pv.primed = true } }
  Component.onCompleted: settle.restart()

  // ---- cameras opened directly (/dev/video*): inotify says when, then one look
  Process {
    running: pv.active
    command: ["bash", "-c", "ls /dev/video* >/dev/null 2>&1 || exec sleep infinity; exec inotifywait -m -q -e open,close /dev/video*"]
    stdout: SplitParser { onRead: camLater.restart() }
  }
  Timer { id: camLater; interval: 300; onTriggered: if (!camProc.running) camProc.running = true }
  Process {
    id: camProc
    command: [pv.bin, "cam"]
    running: pv.active
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: { try { pv.deviceCams = JSON.parse(text).cam || [] } catch (e) {} } }
  }

  // a readable name and icon from the app's desktop entry
  function entryOf(a) { return a.bin ? DesktopEntries.heuristicLookup(a.bin) : DesktopEntries.heuristicLookup(a.app) }
  function nameOf(a) { var e = entryOf(a); return e && e.name ? e.name : a.app.charAt(0).toUpperCase() + a.app.slice(1) }
  function iconOf(a) { var e = entryOf(a); return e && e.icon ? Quickshell.iconPath(e.icon, true) : "" }

  // the log: when an app started and stopped using a device (newest first)
  FileView {
    id: logFile
    path: Quickshell.env("HOME") + "/.local/state/thenotch/privacy.json"
    printErrors: false
    onLoaded: { try { pv.log = JSON.parse(text()) } catch (e) { pv.log = [] } }
    onLoadFailed: pv.log = []
  }
  property var log: []
  function saveLog() { logFile.setText(JSON.stringify(log.slice(0, 300))) }
  // the log folded: one line per app and device — sessions, total time, last use
  readonly property var summary: {
    var by = {}, out = []
    for (var i = 0; i < log.length; i++) {
      var e = log[i], k = e.kind + "/" + e.app
      if (!by[k]) { by[k] = { kind: e.kind, app: e.app, bin: e.bin, count: 0, total: 0, last: 0, now: false }; out.push(by[k]) }
      var g = by[k]
      g.count += 1
      g.total += (e.to || Date.now()) - e.from
      g.last = Math.max(g.last, e.to || Date.now())
      if (!e.to) g.now = true
    }
    return out.sort(function(a, b) { return (b.now - a.now) || (b.last - a.last) })
  }
  function update(kind, now) {
    var before = kind === "mic" ? mic : cam
    var was = before.map(function(a) { return a.app }), is = now.map(function(a) { return a.app })
    var l = log.slice(), changed = false
    now.forEach(function(a) {
      if (was.indexOf(a.app) >= 0) return
      changed = true
      // back within a minute (a call app re-opening the mic): the same session
      for (var j = 0; j < l.length; j++) if (l[j].kind === kind && l[j].app === a.app) {
        if (!l[j].to) return                                        // still open (e.g. after a shell restart)
        if (Date.now() - l[j].to < 60000) { l[j] = Object.assign({}, l[j], { to: 0 }); return }
        break
      }
      l.unshift({ kind: kind, app: a.app, bin: a.bin, from: Date.now(), to: 0 })
      if (announce && primed && notch)
        notch.flash({ key: "privacy-" + kind + a.app, icon: kind === "mic" ? "\u{f036c}" : "\u{f0567}", iconSource: iconOf(a),
                      title: nameOf(a), message: kind === "mic" ? t("использует микрофон", "is using the microphone") : t("использует камеру", "is using the camera"), ms: 3000 })
    })
    before.forEach(function(a) {
      if (is.indexOf(a.app) >= 0) return
      for (var i = 0; i < l.length; i++) if (l[i].kind === kind && l[i].app === a.app && !l[i].to) { l[i] = Object.assign({}, l[i], { to: Date.now() }); changed = true; break }
    })
    // first look after a start: sessions left open by a restart end when last seen
    if (!primed) for (var k = 0; k < l.length; k++)
      if (l[k].kind === kind && !l[k].to && is.indexOf(l[k].app) < 0) { l[k] = Object.assign({}, l[k], { to: l[k].seen || l[k].from }); changed = true }
    if (kind === "mic") mic = now; else cam = now
    if (changed) { log = l; saveLog() }
  }
  function clearLog() { log = []; saveLog() }
  // open sessions note the time now and then, so a restart can close them honestly
  Timer {
    interval: 60000; repeat: true; running: pv.inUse
    onTriggered: { var n = Date.now(); pv.log = pv.log.map(function(e) { return e.to ? e : Object.assign({}, e, { seen: n }) }); pv.saveLog() }
  }
}
