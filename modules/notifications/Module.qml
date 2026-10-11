import QtQuick
import Qt.labs.folderlistmodel
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
  function clearHistory() { ipc(["clear"]) }

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

  // ------------------------------------------------------ live pop-ups
  // Files present when the notch starts are old news: only later ones flash.
  property var seen: ({})
  property bool settled: false
  Timer { interval: 1500; running: true; onTriggered: nmod.settled = true }

  function addPopup(key, raw) {
    if (seen[key]) return
    var s = Object.assign({}, seen); s[key] = true; seen = s
    if (!settled || !notch || !nmod.active) return
    var d
    try { d = JSON.parse(raw) } catch (e) { return }
    var left = d.deadline ? d.deadline - Date.now() : 6000
    notch.flash({
      key: "notif-" + key, big: true, hold: true,
      title: plain(d.summary) || String(d.app || ""),
      message: plain(d.body),
      iconSource: iconFor(d), art: imageFor(d), icon: d.glyph || "󰂚",
      ms: Math.max(3000, Math.min(12000, left)),
      action: function() { nmod.ipc(["invokeKey", key]) },
      dismiss: function() { nmod.ipc(["dismissKey", key]) },
      onHold: function(h) { nmod.ipc([h ? "pause" : "resume"]) }
    })
  }
  function dropPopup(key) { if (notch) notch.removeEvent("notif-" + key) }

  FolderListModel {
    id: popFolder
    folder: "file://" + nmod.dir
    nameFilters: ["*.json"]
    showDirs: false
  }
  Instantiator {
    model: popFolder
    delegate: FileView {
      required property string fileName
      required property string filePath
      readonly property string key: fileName.replace(/\.json$/, "")
      path: filePath
      printErrors: false
      onLoaded: nmod.addPopup(key, text())
      Component.onDestruction: nmod.dropPopup(key)
    }
  }

  // ----------------------------------------------------------- history
  property var historyMap: ({})
  readonly property var history: {
    var list = []
    for (var k in historyMap) list.push(historyMap[k])
    list.sort(function(a, b) { return (b.timestamp || 0) - (a.timestamp || 0) })
    return list
  }
  function setHistory(key, raw) {
    var d
    try { d = JSON.parse(raw) } catch (e) { return }
    d.key = key
    var m = Object.assign({}, historyMap); m[key] = d; historyMap = m
  }
  function unsetHistory(key) {
    if (!historyMap[key]) return
    var m = Object.assign({}, historyMap); delete m[key]; historyMap = m
  }
  FolderListModel {
    id: histFolder
    folder: "file://" + nmod.dir + "history/"
    nameFilters: ["*.json"]
    showDirs: false
  }
  Instantiator {
    model: histFolder
    delegate: FileView {
      required property string fileName
      required property string filePath
      readonly property string key: fileName.replace(/\.json$/, "")
      path: filePath
      printErrors: false
      onLoaded: nmod.setHistory(key, text())
      Component.onDestruction: nmod.unsetHistory(key)
    }
  }

  // refresh DND and "x min ago" while the dashboard is open
  readonly property bool opened: notch !== null && notch.expanded && notch.current === nmod
  onOpenedChanged: if (opened) refreshDnd()
  property int tick: 0
  Timer { interval: 30000; repeat: true; running: nmod.opened; onTriggered: nmod.tick++ }
}
