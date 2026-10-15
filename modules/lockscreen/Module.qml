import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."

// Lock screen: which lock plugin draws it — Omarchy's own or Lock Designs
// (SmoothPixels' own designs only; bin/lockctl trims its picker). Installs it
// from git when asked, keeps only one on, previews without locking.
NotchModule {
  id: lk
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Экран блокировки", "Lock screen")
  icon: "\u{f033e}"
  description: t("Стандартный или Lock Designs", "Standard or Lock Designs")
  inRail: false
  core: true
  settingsSection: "personal"
  sectionOrder: 6
  settingsPage: Component { LockSettings { mod: lk } }

  readonly property string bin: decodeURIComponent(Qt.resolvedUrl("bin/lockctl").toString().replace(/^file:\/\//, ""))
  property var locks: []
  property string busy: ""
  property var queue: []
  Process {
    id: proc
    property var args: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var d = JSON.parse(text)
          if (proc.args[0] === "state") lk.locks = d.locks || []
          else if (!d.ok && lk.notch) lk.notch.flash({ key: "lock", icon: "\u{f033e}", title: lk.t("Не получилось", "Didn't work"), message: d.error || "" })
        } catch (e) {}
        if (proc.args[0] !== "state") { lk.busy = ""; lk.cmd(["state"]) }
        lk.next()
      }
    }
  }
  function next() {
    if (proc.running || !queue.length) return
    proc.args = queue[0]; queue = queue.slice(1)
    proc.command = [bin].concat(proc.args); proc.running = true
  }
  function cmd(args) { queue = queue.concat([args]); next() }
  function run(args) { busy = args[1] || args[0]; cmd(args) }
  readonly property bool watching: active && notch !== null && notch.settingsOpen && notch.settingsSection === "personal"
  onWatchingChanged: if (watching) cmd(["state"])
}
