import QtQuick
import Quickshell.Io

// One books widget (the main one or a copy): its settings, the books from
// its folders (and Foliate's history), and which one it shows: the last one
// read, a random one, or each in turn.
Item {
  id: fd
  property var mod: null
  property string wid: ""
  visible: false
  function cfg(key, fallback) { return mod ? mod.copies.cfg(wid, key, fallback) : fallback }
  function persist(values) { mod.copies.set(wid, values) }

  readonly property var folders: cfg("folders", [mod ? mod.home + "/Books" : ""])
  readonly property bool subfolders: cfg("subfolders", true) !== false
  readonly property bool history: cfg("history", true) !== false      // books Foliate has opened, wherever they are
  readonly property string mode: String(cfg("mode", "last"))          // last | random | cycle
  readonly property int interval: Number(cfg("interval", 60))         // seconds (random, cycle)
  readonly property int size: Number(cfg("size", 380))                // the widget's width, px
  readonly property string titleFont: String(cfg("titleFont", "serif"))
  readonly property string authorFont: String(cfg("authorFont", "default"))
  readonly property bool showAuthor: cfg("author", true) !== false
  readonly property bool showProgress: cfg("progress", true) !== false
  readonly property bool enabled_: wid === (mod ? mod.moduleId : "") ? (mod && mod.deskEnabled) : cfg("enabled", true) !== false
  readonly property bool on: !!mod && mod.active && enabled_

  property var books: []                      // from booksctl
  property var seq: []
  property int pos: 0
  readonly property int count: seq.length
  readonly property var current: count ? books[seq[(pos % count + count) % count]] || null : null

  // the order to go through: by last read (last), shuffled (random) or as found (cycle)
  function reorder() {
    var keep = current ? current.path : ""
    var o = []
    for (var i = 0; i < books.length; i++) o.push(i)
    if (mode === "random") for (var j = o.length - 1; j > 0; j--) { var r = Math.floor(Math.random() * (j + 1)); var x = o[j]; o[j] = o[r]; o[r] = x }
    else if (mode === "last") o.sort(function(a, b) { return books[b].read - books[a].read })
    var p = 0
    // "last" always starts at the latest; the others stay on the book shown
    if (mode !== "last") for (var k = 0; k < o.length && keep; k++) if (books[o[k]].path === keep) { p = k; break }
    seq = o; pos = p
  }
  onBooksChanged: reorder()
  onModeChanged: reorder()
  function step(d) { if (count > 1) { pos = ((pos + d) % count + count) % count; ticker.restart() } }

  Process {
    id: lister
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var d = JSON.parse(text)
          // only a real change re-orders (a rescan every half minute must not jump around)
          if (d.ok && JSON.stringify(d.books) !== JSON.stringify(fd.books)) fd.books = d.books || []
        } catch (e) {}
      }
    }
  }
  function rescan() {
    if (!mod) return
    if (lister.running) { rescanLater.restart(); return }
    lister.command = [mod.bin, "list"].concat(subfolders ? [] : ["--flat"]).concat(history ? [] : ["--no-history"]).concat(folders)
    lister.running = true
  }
  Timer { id: rescanLater; interval: 400; onTriggered: fd.rescan() }
  onFoldersChanged: if (on) rescanLater.restart()
  onSubfoldersChanged: if (on) rescanLater.restart()
  onHistoryChanged: if (on) rescanLater.restart()
  onOnChanged: if (on) rescan()
  Component.onCompleted: if (on) rescan()
  // Foliate saves the place as you read: pick up progress and the last book
  Timer { interval: 30000; repeat: true; running: fd.on; onTriggered: fd.rescan() }
  Timer { id: ticker; interval: Math.max(5, fd.interval) * 1000; repeat: true; running: fd.on && fd.mode !== "last" && fd.count > 1; onTriggered: fd.step(1) }

  // the folder picker in the settings
  Process {
    id: picker
    command: [fd.mod ? fd.mod.bin : "true", "folders"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var add = text.split("\n").filter(function(l) { return l.length > 0 })
        if (add.length) fd.addFolders(add)
      }
    }
  }
  function pickFolders() { if (!picker.running) picker.running = true }
  function addFolders(list) {
    var f = folders.slice()
    for (var i = 0; i < list.length; i++) {
      var p = String(list[i]).trim().replace(/^~(?=\/|$)/, mod.home).replace(/\/+$/, "")
      if (p && f.indexOf(p) < 0) f.push(p)
    }
    persist({ folders: f })
  }
  function removeFolder(p) { persist({ folders: folders.filter(function(x) { return x !== p }) }) }
}
