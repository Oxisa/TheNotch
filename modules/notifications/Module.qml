import QtQuick
import Quickshell
import Quickshell.Io
import "../.."

// Notifications as a TheNotch dashboard. The notification daemon
// (osia.notifications, a headless clone of omarchy.notifications) keeps each
// live popup as a file in ~/.local/state/omarchy/notifications/ and takes
// commands over IPC (dismissKey / invokeKey / pause / resume), so the notch
// only draws: a new file flashes out of the notch; hovering holds it (and
// pauses the daemon's clock), a click runs its action, × dismisses it. When
// the daemon expires or dismisses one, its file goes and so does the event.
// The dashboard is the history (newest first), Do Not Disturb and Clear.
NotchModule {
  id: nmod
  title: t("title")
  icon: "󰂚"
  description: notch && notch.lang === "ru" ? "Всплывающие уведомления из чёлки и их история" : "Pop-ups out of the notch and their history"
  pageWidth: 440
  noIcon: true
  settingsSection: "system"
  sectionOrder: 5
  settingsPage: Component { NotificationsSettings { mod: nmod } }
  page: Component { Page { mod: nmod } }

  readonly property string dir: Quickshell.env("HOME") + "/.local/state/omarchy/notifications/"
  readonly property var strings: ({
    en: { title: "Notifications", dnd: "Do not disturb", dndHint: "No pop-ups; notifications still land in the history",
          clear: "Clear", empty: "Nothing here yet", now: "just now", min: "{0} min ago", hour: "{0} h ago", day: "{0} d ago" },
    ru: { title: "Уведомления", dnd: "Не беспокоить", dndHint: "Без всплывашек; уведомления всё равно попадают в историю",
          clear: "Очистить", empty: "Пока пусто", now: "только что", min: "{0} мин назад", hour: "{0} ч назад", day: "{0} дн назад" }
  })
  function t(k, a) {
    var lang = notch ? notch.lang : "en"
    var s = (strings[lang] || strings.en)[k] || strings.en[k] || k
    return a !== undefined ? String(s).replace("{0}", a) : s
  }

  // ------------------------------------------------------- daemon IPC
  function ipc(args) {
    Quickshell.execDetached(["qs", "-p", Quickshell.shellDir, "ipc", "call", "notifications"].concat(args))
  }
  property bool dnd: false
  Process {
    id: dndProc
    command: ["qs", "-p", Quickshell.shellDir, "ipc", "call", "notifications", "dndState"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: nmod.dnd = String(text).trim() === "on" }
  }
  function refreshDnd() { if (!dndProc.running) dndProc.running = true }
  function setDnd(on) { dnd = on; ipc(["setDnd", on ? "on" : "off"]); dndRefresh.restart() }
  Timer { id: dndRefresh; interval: 600; onTriggered: nmod.refreshDnd() }
  Component.onCompleted: refreshDnd()

  // ------------------------------------------------------------ helpers
  function plain(s) { return String(s || "").replace(/<[^>]*>/g, "").replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").trim() }
  function iconFor(d) {
    var i = String(d.appIcon || "")
    if (i.indexOf("/") === 0) return "file://" + i
    if (i.indexOf("file://") === 0) return i
    var found = i ? Quickshell.iconPath(i, true) : ""
    if (!found && d.app) found = Quickshell.iconPath(String(d.app).toLowerCase(), true)
    return found || ""
  }
  function imageFor(d) {
    var i = String(d.image || "")
    return i.indexOf("/") === 0 ? "file://" + i : i.indexOf("file://") === 0 ? i : ""
  }
  function ago(ms) {
    var m = Math.floor((Date.now() - ms) / 60000)
    if (m < 1) return t("now")
    if (m < 60) return t("min", m)
    if (m < 1440) return t("hour", Math.floor(m / 60))
    return t("day", Math.floor(m / 1440))
  }

  // --------------------------------------------- reading the daemon's files
  // A small poll (once a second) rather than a folder watch: the watch
  // missed deletions, so cleared notifications lingered in the list.
  property string lastRaw: ""
  Process {
    id: scan
    command: ["bash", "-c",
      "d=$1; for f in \"$d\"/*.json; do [ -e \"$f\" ] || continue; n=${f##*/}; printf 'P\\t%s\\t' \"${n%.json}\"; tr -d '\\n' < \"$f\"; echo; done; " +
      "for f in \"$d\"/history/*.json; do [ -e \"$f\" ] || continue; n=${f##*/}; printf 'H\\t%s\\t' \"${n%.json}\"; tr -d '\\n' < \"$f\"; echo; done",
      "--", nmod.dir.replace(/\/$/, "")]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: nmod.ingest(text) }
  }
  Timer { interval: 1000; repeat: true; running: true; triggeredOnStart: true; onTriggered: nmod.rescan() }
  function rescan() { if (!scan.running) scan.running = true }

  function ingest(raw) {
    if (raw === lastRaw) return
    lastRaw = raw
    var popups = {}, hist = {}
    var lines = String(raw).split("\n")
    for (var i = 0; i < lines.length; i++) {
      var parts = lines[i].split("\t")
      if (parts.length < 3) continue
      var d
      try { d = JSON.parse(parts.slice(2).join("\t")) } catch (e) { continue }
      d.key = parts[1]
      if (parts[0] === "P") popups[d.key] = d; else hist[d.key] = d
    }
    syncPopups(popups)
    historyMap = hist
  }

  // ------------------------------------------------------ live pop-ups
  // Identical notifications (same app, title and text) share one event with
  // a ×N count; × dismisses the whole group.
  function sigOf(d) { return String(d.app || "") + "\u0001" + plain(d.summary) + "\u0001" + plain(d.body) }
  function hashOf(str) { var h = 0; for (var i = 0; i < str.length; i++) h = (h * 31 + str.charCodeAt(i)) | 0; return (h >>> 0).toString(16) }

  property var liveKeys: ({})            // file key -> group sig
  property var groups: ({})              // sig -> { keys: [...], count, data }
  // Files present when the notch starts are old news: only later ones flash.
  property bool settled: false
  property bool firstScan: true

  function syncPopups(popups) {
    var known = liveKeys, next = {}, k
    var g = {}
    for (var s in groups) g[s] = { keys: groups[s].keys.slice(), count: groups[s].count, data: groups[s].data }
    for (k in popups) {
      var sig = sigOf(popups[k])
      next[k] = sig
      if (known[k] !== undefined) continue
      if (!g[sig]) g[sig] = { keys: [], count: 0, data: popups[k] }
      g[sig].keys.push(k); g[sig].count += 1; g[sig].data = popups[k]
      if (!firstScan && settled && notch && nmod.active) flashGroup(sig, g[sig])
    }
    for (k in known) {
      if (next[k] !== undefined) continue
      var gs = g[known[k]]
      if (!gs) continue
      gs.keys = gs.keys.filter(function(x) { return x !== k })
      if (!gs.keys.length) { delete g[known[k]]; if (notch) notch.removeEvent("notif-" + hashOf(known[k])) }
    }
    liveKeys = next
    groups = g
    firstScan = false
  }
  function flashGroup(sig, grp) {
    var d = grp.data
    var keys = grp.keys.slice()
    var latest = keys[keys.length - 1]
    var left = d.deadline ? d.deadline - Date.now() : 6000
    notch.flash({
      key: "notif-" + hashOf(sig), big: true, hold: true,
      title: (plain(d.summary) || String(d.app || "")) + (grp.count > 1 ? "  ×" + grp.count : ""),
      message: plain(d.body),
      iconSource: iconFor(d), art: imageFor(d), icon: d.glyph || "󰂚",
      ms: Math.max(3000, Math.min(12000, left)),
      action: function() { nmod.ipc(["invokeKey", latest]) },
      dismiss: function() { for (var i = 0; i < keys.length; i++) nmod.ipc(["dismissKey", keys[i]]) },
      onHold: function(h) { nmod.ipc([h ? "pause" : "resume"]) }
    })
  }
  Timer { interval: 1500; running: true; onTriggered: nmod.settled = true }

  // ----------------------------------------------------------- history
  // grouped like the pop-ups: one card per identical notification, newest first
  property var historyMap: ({})
  readonly property var history: {
    var bySig = {}, order = []
    for (var k in historyMap) {
      var d = historyMap[k], sig = sigOf(d)
      if (!bySig[sig]) { bySig[sig] = { item: d, count: 0 }; order.push(sig) }
      bySig[sig].count += 1
      if ((d.timestamp || 0) > (bySig[sig].item.timestamp || 0)) bySig[sig].item = d
    }
    var list = order.map(function(s) { var it = Object.assign({}, bySig[s].item); it.count = bySig[s].count; return it })
    list.sort(function(a, b) { return (b.timestamp || 0) - (a.timestamp || 0) })
    return list
  }
  function clearHistory() {
    ipc(["clear"])
    historyMap = ({})                     // gone from the list at once; the next scan confirms
    lastRaw = ""
    clearRescan.restart()
  }
  Timer { id: clearRescan; interval: 700; onTriggered: nmod.rescan() }

  // refresh DND and "x min ago" while the dashboard is open
  readonly property bool opened: notch !== null && notch.expanded && notch.current === nmod
  onOpenedChanged: if (opened) refreshDnd()
  property int tick: 0
  Timer { interval: 30000; repeat: true; running: nmod.opened; onTriggered: nmod.tick++ }
}
