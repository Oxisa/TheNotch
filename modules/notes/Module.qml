import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."

// Notes: sticky notes in the notch (a tool in Centre) — pastel cards, the
// first line is the title, "[ ]" lines become tick boxes, eight colours,
// search, archive. Kept in ~/.local/share/thenotch/notes.json and copied as
// Markdown to Documents/Notes (one .md per note). After Jot (MIT) and macOS
// Noty — the idea, not their code.
NotchModule {
  id: nm
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Заметки", "Notes")
  icon: "\u{f178e}"
  description: t("Стикеры с галочками прямо в чёлке", "Sticky notes with tick boxes in the notch")
  pageWidth: 760
  page: Component { NotesPage { mod: nm } }

  readonly property var colors: [
    { id: "lemon", c: "#f6e58d" }, { id: "peach", c: "#f8c291" }, { id: "rose", c: "#f6a6b2" }, { id: "lilac", c: "#cdb4f0" },
    { id: "sky", c: "#a3d5f7" }, { id: "mint", c: "#b8e6c1" }, { id: "sand", c: "#e6d3b3" }, { id: "slate", c: "#c9ced6" }
  ]
  function colorOf(id) { for (var i = 0; i < colors.length; i++) if (colors[i].id === id) return colors[i].c; return colors[0].c }

  FileView {
    id: file
    path: Quickshell.env("HOME") + "/.local/share/thenotch/notes.json"
    printErrors: false
    onLoaded: { try { nm.notes = JSON.parse(text()) } catch (e) { nm.notes = [] } }
    onLoadFailed: nm.notes = []
  }
  property var notes: []
  function save() {
    Quickshell.execDetached(["mkdir", "-p", Quickshell.env("HOME") + "/.local/share/thenotch"])
    file.setText(JSON.stringify(notes, null, 1))
    if (exportMd) exportSoon.restart()
  }
  // every note as Markdown in Documents/Notes (bin/notes2md), first line = title
  function opt(key, fallback) { return notch ? notch.moduleOpt("notes", key, fallback) : fallback }
  function persist(values) { if (notch) notch.modulePersist("notes", values) }
  readonly property bool exportMd: opt("markdown", true) !== false
  readonly property string mdFolder: t("Заметки", "Notes")
  Timer { id: exportSoon; interval: 400; onTriggered: Quickshell.execDetached([decodeURIComponent(Qt.resolvedUrl("bin/notes2md").toString().replace(/^file:\/\//, "")), file.path, nm.mdFolder]) }
  function openFolder() { Quickshell.execDetached(["bash", "-c", "d=$(xdg-user-dir DOCUMENTS); mkdir -p \"$d/$1\"; xdg-open \"$d/$1\"", "--", mdFolder]) }
  function add() {
    var n = { id: "n" + Date.now(), text: "", color: colors[notes.length % colors.length].id, archived: false, at: Date.now() }
    notes = [n].concat(notes); save(); return n.id
  }
  function update(id, v) { notes = notes.map(function(n) { return n.id === id ? Object.assign({}, n, v, { at: Date.now() }) : n }); save() }
  function remove(id) { notes = notes.filter(function(n) { return n.id !== id }); save() }
  // tick a "[ ]" / "[x]" line
  function toggleLine(id, i) {
    var n = notes.filter(function(x) { return x.id === id })[0]
    if (!n) return
    var lines = n.text.split("\n")
    lines[i] = /^\s*\[[xX✓]\]/.test(lines[i]) ? lines[i].replace(/\[[xX✓]\]/, "[ ]") : lines[i].replace("[ ]", "[x]")
    update(id, { text: lines.join("\n") })
  }
}
