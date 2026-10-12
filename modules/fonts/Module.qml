import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."
import "../../fonts"

// Fonts: one choice for the notch and the settings, one for the desktop
// widgets (the Fonts singleton carries both). Presets: the system font,
// Goetia (blackletter for Latin, Noto Serif for Cyrillic — the quote's look),
// Deutsch Gothic (experimental), or any installed family. bin/fontctl adds
// fonts and the Goetia alias.
NotchModule {
  id: fm
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Шрифты", "Fonts")
  icon: "\u{f0281}"
  description: t("Шрифт интерфейса и виджетов", "The interface and widget fonts")
  inRail: false
  core: true
  settingsSection: "personal"
  sectionOrder: 4
  settingsPage: Component { FontsSettings { mod: fm } }

  readonly property string bin: decodeURIComponent(Qt.resolvedUrl("bin/fontctl").toString().replace(/^file:\/\//, ""))
  property var families: []
  property string busy: ""
  Process {
    id: proc
    property var args: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var d = null
        try { d = JSON.parse(text) } catch (e) {}
        fm.busy = ""
        if (!d) return
        if (proc.args[0] === "list") { fm.families = d.families || []; return }
        if (!d.ok && fm.notch) fm.notch.flash({ key: "fonts", icon: "\u{f0281}", title: fm.t("Шрифт не добавлен", "No font added"), message: d.error || "" })
        if (d.ok && fm.pending) { fm.notch.persist(fm.pending); fm.pending = null }
        // fontconfig learned a new font: the shell sees it after a restart
        if (d.restart) Quickshell.execDetached(["bash", "-c", "sleep 0.6; omarchy restart shell"])
        else fm.list()
      }
    }
  }
  function run(args) { if (proc.running) return; busy = args[0]; proc.args = args; proc.command = [bin].concat(args); proc.running = true }
  function list() { run(["list"]) }
  property var pending: null
  // pick a family for "ui" or "desk"; Goetia first makes sure its alias exists
  function choose(target, family) {
    var v = {}; v[target === "ui" ? "fontUi" : "fontDesk"] = family
    if (family === "TheNotch Goetia" && families.indexOf("UnifrakturMaguntia") < 0) { pending = v; run(["preset", "goetia"]) }
    else notch.persist(v)
  }
  function addFiles() {
    if (pickProc.running) return
    pickProc.running = true
  }
  Process {
    id: pickProc
    command: ["omarchy-file-select", "--title", fm.t("Шрифт (.ttf, .otf, .zip)", "Font (.ttf, .otf, .zip)"), "--multiple", "--extensions", "ttf otf zip"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: { var f = String(text).trim().split("\n").filter(function(x) { return x }); if (f.length) fm.run(["install"].concat(f)) } }
  }
  readonly property bool watching: active && notch !== null && notch.settingsOpen && notch.settingsSection === "personal"
  onWatchingChanged: if (watching) list()
}
