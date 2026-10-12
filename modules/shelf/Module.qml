import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."

// Shelf: somewhere to put a thing down between apps. Drop a file, a link or
// some text on the notch and it waits here; drag it out into any app later,
// or open / show / copy it. Files stay where they are (the shelf keeps the
// path). After oShelf (i12bp8, MIT) — the idea, not its code.
NotchModule {
  id: sh
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Полка", "Shelf")
  icon: "\u{f0120}"
  description: t("Бросьте файл или текст на чёлку — заберёте потом", "Drop a file or text on the notch — pick it up later")
  pageWidth: 640
  page: Component { ShelfPage { mod: sh } }

  FileView {
    id: file
    path: Quickshell.env("HOME") + "/.local/share/thenotch/shelf.json"
    printErrors: false
    onLoaded: { try { sh.items = JSON.parse(text()) } catch (e) { sh.items = [] } }
    onLoadFailed: sh.items = []
  }
  property var items: []
  function save() { Quickshell.execDetached(["mkdir", "-p", Quickshell.env("HOME") + "/.local/share/thenotch"]); file.setText(JSON.stringify(items, null, 1)) }
  // what a drop brings: file URLs, other URLs, or text
  function take(urls, text) {
    var add = []
    ;(urls || []).forEach(function(u) {
      u = String(u)
      if (u.indexOf("file://") === 0) { var p = decodeURIComponent(u.slice(7)); add.push({ kind: "file", value: p, name: p.split("/").pop() }) }
      else if (u) add.push({ kind: "url", value: u, name: u.replace(/^https?:\/\//, "").slice(0, 60) })
    })
    if (!add.length && text && String(text).trim()) {
      var s = String(text).trim()
      add.push(/^https?:\/\/\S+$/.test(s) ? { kind: "url", value: s, name: s.replace(/^https?:\/\//, "").slice(0, 60) } : { kind: "text", value: s, name: s.split("\n")[0].slice(0, 60) })
    }
    if (!add.length) return
    var now = Date.now()
    items = add.map(function(x, i) { return Object.assign({ id: "s" + now + i, at: now }, x) }).concat(items).slice(0, 60)
    save()
    if (notch) notch.flash({ key: "shelf", icon: "\u{f0120}", title: t("На полке", "On the shelf"), message: add.length > 1 ? add.length + t(" шт.", " items") : add[0].name, ms: 1800 })
  }
  function remove(id) { items = items.filter(function(x) { return x.id !== id }); save() }
  function clear() { items = []; save() }
  function isImage(it) { return it.kind === "file" && /\.(png|jpe?g|webp|gif|bmp|svg)$/i.test(it.value) }
  function open(it) { Quickshell.execDetached(["xdg-open", it.value]) }
  function reveal(it) { Quickshell.execDetached(["xdg-open", it.value.slice(0, it.value.lastIndexOf("/")) || "/"]) }
  function copy(it) {
    if (it.kind === "file") Quickshell.execDetached(["bash", "-c", "printf 'file://%s\\n' \"$1\" | wl-copy --type text/uri-list", "--", it.value])
    else Quickshell.execDetached(["wl-copy", it.value])
  }
}
