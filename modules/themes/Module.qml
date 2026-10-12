import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."
import "../../fonts"

// Themes (Personalisation): every Omarchy theme as a card — its preview and
// colours; a click applies it. With "matching wallpaper" on, the theme comes
// with the wallpaper from your folder that speaks its colours, and any colour
// can become a new theme. The colour work is Omapalette's engine
// (janooh37-hue/omapalette, MIT; its bin/omapalette, run as is, over aether).
NotchModule {
  id: th
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Темы", "Themes")
  icon: "\u{f03d8}"
  description: t("Темы Omarchy, обои в тон и тема из любого цвета", "Omarchy themes, matching wallpapers and a theme from any colour")
  inRail: false
  core: true
  settingsSection: "personal"
  sectionOrder: 1
  settingsPage: Component { ThemesSettings { mod: th } }
  function opt(key, fallback) { return notch ? notch.moduleOpt("themes", key, fallback) : fallback }
  function persist(values) { if (notch) notch.modulePersist("themes", values) }

  readonly property string engine: decodeURIComponent(Qt.resolvedUrl("../../vendor/omapalette/bin/omapalette").toString().replace(/^file:\/\//, ""))
  property bool haveEngine: true
  FileView { path: th.engine; printErrors: false; onLoadFailed: th.haveEngine = false; onLoaded: th.haveEngine = true }
  // the wallpaper folder Omapalette matches against: Wallpaper's first folder
  readonly property string library: { var w = notch ? notch.moduleById("wallpaper") : null; return w && w.folders.length ? w.folders[0] : Quickshell.env("HOME") + "/Pictures/Wallpapers" }
  readonly property bool matchWallpaper: opt("matchWallpaper", true) !== false

  property var themes: []
  property var current: ({})
  property string busy: ""
  property var queue: []
  Process {
    id: proc
    property var args: []
    environment: ({ OMAPALETTE_WALLPAPERS: th.library })
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var d = null
        try { d = JSON.parse(text) } catch (e) {}
        var a = proc.args
        if (a[0] === "themes" && d) th.themes = d
        else if (a[0] === "current" && d) th.current = d
        else { th.busy = ""; th.queue = th.queue.concat([["current"]]) }
        th.next()
      }
    }
  }
  function next() {
    if (proc.running || !queue.length) return
    proc.args = queue[0]; queue = queue.slice(1)
    if (["themes", "current"].indexOf(proc.args[0]) < 0) busy = proc.args[0] + (proc.args[1] ? ":" + proc.args[1] : "")
    proc.command = proc.args[0] === "set" ? ["omarchy-theme-set", proc.args[1]] : [engine].concat(proc.args)
    proc.running = true
  }
  function cmd(args) { queue = queue.concat([args]); next() }
  function apply(name) { cmd(matchWallpaper && haveEngine ? ["apply", name] : ["set", name]) }
  function fromColor(hex, light) { cmd(light ? ["from-color", "--light", hex] : ["from-color", hex]); cmd(["themes"]) }
  function index() { cmd(["index"]) }
  readonly property bool watching: active && notch !== null && notch.settingsOpen && notch.settingsSection === "personal"
  onWatchingChanged: if (watching) { cmd(["themes"]); cmd(["current"]) }
}
