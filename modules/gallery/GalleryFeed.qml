import QtQuick
import Quickshell.Io

// One gallery widget's slideshow (the main one or a copy): its settings, the
// files from its folders, their order and the timer. Gallery's Module.qml
// keeps one per widget.
Item {
  id: fd
  property var mod: null
  property string wid: ""
  visible: false
  function cfg(key, fallback) { return mod ? mod.copies.cfg(wid, key, fallback) : fallback }

  readonly property var folders: cfg("folders", [mod ? mod.home + "/Pictures" : ""])
  readonly property bool subfolders: cfg("subfolders", true) !== false
  readonly property bool withVideos: cfg("videos", true) !== false
  readonly property int interval: Number(cfg("interval", 10))        // seconds
  readonly property bool shuffle: cfg("order", "shuffle") === "shuffle"
  readonly property string look: String(cfg("look", "carousel"))    // carousel | single
  readonly property string effect: String(cfg("effect", "kenburns")) // kenburns | fade | slide (single look)
  readonly property int size: Number(cfg("size", 480))               // the widget's width, px
  readonly property bool caption: cfg("caption", false) === true     // folder · date under the picture
  readonly property bool enabled_: wid === (mod ? mod.moduleId : "") ? (mod && mod.deskEnabled) : cfg("enabled", true) !== false
  readonly property bool on: !!mod && mod.active && enabled_

  property var all: []                        // [{path, video, date}] from galleryctl
  readonly property var files: withVideos ? all : all.filter(function(f) { return !f.video })
  property var seq: []                        // indexes into files, shuffled or not
  property int pos: 0                         // place in `seq`
  readonly property int count: seq.length
  function at(k) {
    if (!count) return null
    return files[seq[((pos + k) % count + count) % count]] || null
  }
  readonly property var current: at(0)
  readonly property var prevItem: count > 1 ? at(-1) : null
  readonly property var nextItem: count > 1 ? at(1) : null

  function reorder() {
    var keep = current ? current.path : ""
    var o = []
    for (var i = 0; i < files.length; i++) o.push(i)
    if (shuffle) for (var j = o.length - 1; j > 0; j--) { var r = Math.floor(Math.random() * (j + 1)); var x = o[j]; o[j] = o[r]; o[r] = x }
    var p = 0
    // stay on the picture shown, if it's still there
    for (var k = 0; k < o.length && keep; k++) if (files[o[k]].path === keep) { p = k; break }
    seq = o; pos = p
  }
  onFilesChanged: reorder()
  onShuffleChanged: reorder()
  function step(d) { if (count > 1) { pos = ((pos + d) % count + count) % count; ticker.restart() } }

  Process {
    id: lister
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: { try { var d = JSON.parse(text); if (d.ok) fd.all = d.files || [] } catch (e) {} }
    }
  }
  function rescan() {
    if (!mod) return
    if (lister.running) { rescanLater.restart(); return }
    lister.command = [mod.bin, "list"].concat(subfolders ? [] : ["--flat"]).concat(folders)
    lister.running = true
  }
  Timer { id: rescanLater; interval: 400; onTriggered: fd.rescan() }
  onFoldersChanged: if (on) rescanLater.restart()
  onSubfoldersChanged: if (on) rescanLater.restart()
  onOnChanged: if (on) rescan()
  Component.onCompleted: if (on) rescan()
  // new files show up without a restart
  Timer { interval: 300000; repeat: true; running: fd.on; onTriggered: fd.rescan() }
  // the slideshow itself
  Timer { id: ticker; interval: Math.max(2, fd.interval) * 1000; repeat: true; running: fd.on && fd.count > 1; onTriggered: fd.step(1) }

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
    mod.copies.set(wid, { folders: f })
  }
  function removeFolder(p) { mod.copies.set(wid, { folders: folders.filter(function(x) { return x !== p }) }) }
  function persist(values) { mod.copies.set(wid, values) }
}
