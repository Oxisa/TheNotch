import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."

// Wallpapers: the current one, the theme's own, your folders (they stay
// available whatever the theme — after Everywall, pierrenel), and videos
// played by TheNotch itself (vendor/livewallpaper, after tenzin's Live
// Wallpaper, MIT). Images go through Omarchy's
// own `omarchy theme bg set`.
NotchModule {
  id: wp
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Обои", "Wallpaper")
  icon: "\u{f0e09}"
  description: t("Обои темы, свои папки и живые видео-обои", "Theme wallpapers, your folders and live video wallpapers")
  inRail: false
  core: true
  settingsSection: "personal"
  sectionOrder: 3
  settingsPage: Component { WallpaperSettings { mod: wp } }
  function opt(key, fallback) { return notch ? notch.moduleOpt("wallpaper", key, fallback) : fallback }
  function persist(values) { if (notch) notch.modulePersist("wallpaper", values) }

  readonly property string bin: decodeURIComponent(Qt.resolvedUrl("bin/wallctl").toString().replace(/^file:\/\//, ""))
  readonly property string home: Quickshell.env("HOME")
  readonly property var folders: opt("folders", [home + "/Pictures/WALLPAPER", home + "/Pictures/Wallpapers"])
  property var st: ({})
  property var posters: ({})
  property var queue: []
  Process {
    id: proc
    property var args: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var d = JSON.parse(text)
          if (proc.args[0] === "state") wp.st = d
          else if (proc.args[0] === "thumbs") wp.posters = Object.assign({}, wp.posters, d)
          else Qt.callLater(function() { wp.cmd(["state"]) })
        } catch (e) {}
        wp.next()
      }
    }
  }
  function next() {
    if (proc.running || !queue.length) return
    proc.args = queue[0]; queue = queue.slice(1)
    proc.command = [bin].concat(proc.args); proc.running = true
  }
  function cmd(args) { queue = queue.concat([args]); next() }
  function set(f) { st = Object.assign({}, st, { background: f }); cmd(["set", f]) }
  readonly property bool watching: active && notch !== null && notch.settingsOpen && notch.settingsSection === "personal"
  onWatchingChanged: if (watching) {
    cmd(["state"])
    var dirs = folders.concat([st.themeDir || "", st.userThemeDir || ""])
    for (var i = 0; i < dirs.length; i++) if (dirs[i]) cmd(["thumbs", dirs[i]])
  }
  function isVideo(f) { return /\.(mp4|mkv|webm|mov|m4v)$/i.test(f) }
}
