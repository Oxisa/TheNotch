import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."

// Gallery: desktop widgets that cycle through the pictures and videos of one
// or more folders, in order or shuffled, every N seconds. Two looks: a
// carousel (the current one in the middle, the previous and next blurred at
// the sides) or one picture with an effect (Ken Burns, fade, slide). A click
// shows the file in the file manager and opens it. Any number of copies,
// each with its own folders and look (DeskCopies); GalleryFeed runs one
// widget's slideshow. bin/galleryctl lists the files, makes video stills and
// opens things. Widget only: no dashboard.
NotchModule {
  id: gm
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Галерея", "Gallery")
  icon: "\u{f024f}"
  description: t("Картинки и видео из папок по кругу на рабочем столе", "Pictures and videos from your folders in turn on the desktop")
  inRail: false
  function opt(key, fallback) { return notch ? notch.moduleOpt("gallery", key, fallback) : fallback }
  function persist(values) { if (notch) notch.modulePersist("gallery", values) }
  readonly property string home: Quickshell.env("HOME")

  // ------------------------------------------------------------ widgets
  widgetTitle: t("Галерея", "Gallery")
  widgetIcon: "\u{f024f}"
  widgetPage: Component { GallerySettings { mod: gm } }
  deskEnabled: opt("widget", false) === true
  function setDeskEnabled(on) { persist({ widget: on }) }
  deskDefault: ({ x: 0.36, y: 0.30 })
  deskWidget: Component { GalleryWidget { mod: gm } }
  DeskCopies {
    id: copiesObj
    mod: gm
    icon: "\u{f024f}"
    defaultPos: gm.deskDefault
    component: Component { GalleryWidget { mod: gm } }
  }
  readonly property var copies: copiesObj
  deskList: copiesObj.list

  // one slideshow per widget
  Instantiator {
    id: feeds
    model: copiesObj.wids
    delegate: GalleryFeed { required property string modelData; mod: gm; wid: modelData }
  }
  function feed(wid) {
    var w = wid || moduleId
    for (var i = 0; i < feeds.count; i++) { var f = feeds.objectAt(i); if (f && f.wid === w) return f }
    return null
  }

  // ------------------------------------------------------------ shared
  readonly property string bin: decodeURIComponent(Qt.resolvedUrl("bin/galleryctl").toString().replace(/^file:\/\//, ""))

  // video stills for the blurred sides: path → still
  property var thumbs: ({})
  property var thumbQueue: []
  Process {
    id: thumber
    property string file: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var t = text.trim(), m = Object.assign({}, gm.thumbs)
        m[thumber.file] = t
        gm.thumbs = m
        gm.nextThumb()
      }
    }
  }
  function nextThumb() {
    if (thumber.running || !thumbQueue.length) return
    thumber.file = thumbQueue[0]; thumbQueue = thumbQueue.slice(1)
    thumber.command = [bin, "thumb", thumber.file]; thumber.running = true
  }
  // read from bindings: only reads `thumbs`; a missing still is asked for later
  function stillOf(f) {
    if (!f) return ""
    if (!f.video) return f.path
    var t = thumbs[f.path]
    if (t === undefined) Qt.callLater(askThumb, f.path)
    return t || ""
  }
  function askThumb(path) {
    if (thumbs[path] !== undefined || thumbQueue.indexOf(path) >= 0 || thumber.file === path) return
    thumbQueue = thumbQueue.concat([path]); nextThumb()
  }
  // a local path as a file:// URL (#, ? and the like escaped)
  function url(p) { return p ? "file://" + p.split("/").map(encodeURIComponent).join("/") : "" }

  function open(f) { if (f) Quickshell.execDetached([bin, "open", f.path]) }

  // "Holiday · 12 Oct 2025": the file's folder and the day it was made
  function captionOf(f) {
    if (!f) return ""
    var parts = f.path.split("/")
    var folder = parts.length > 1 ? parts[parts.length - 2] : ""
    var d = f.date ? new Date(f.date * 1000) : null
    var day = d ? d.toLocaleDateString(Qt.locale(ru ? "ru_RU" : "en_GB"), "d MMM yyyy") : ""
    return [folder, day].filter(function(x) { return x }).join("  ·  ")
  }
}
