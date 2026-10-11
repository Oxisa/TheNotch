import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."

// Displays: monitors' arrangement, resolution, refresh rate, scale and
// brightness (DDC), and text size. Changes go through the Display Settings
// plugin's backend (omarchy-display by Amin Marashi, MIT), which writes the
// "omarchy-display" block of ~/.config/hypr/monitors.lua — so both stay in
// step. Text size is Omarchy's own `omarchy display text size`.
NotchModule {
  id: dm
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Дисплеи", "Displays")
  icon: "\u{f037a}"
  description: t("Мониторы: расположение, разрешение, частота, масштаб, яркость", "Monitors: arrangement, resolution, refresh rate, scale, brightness")
  inRail: false
  settingsSection: "displays"
  sectionOrder: 1
  settingsPage: Component { DisplaysSettings { mod: dm } }

  readonly property string backend: Quickshell.env("HOME") + "/.config/omarchy/plugins/omarchy-display/bin/display-settings"
  property bool hasBackend: true
  property var displays: []
  property var brightness: ({})                  // name -> percent | -1 (no DDC)
  property int textSize: 12
  property string error: ""
  property var queue: []
  Process {
    id: proc
    property var args: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var a = proc.args, d = null
        try { d = JSON.parse(text) } catch (e) {}
        if (a[0] === "state" && d) dm.displays = d.displays || []
        else if (a[0] === "brightness" && d) { var b = Object.assign({}, dm.brightness); b[a[1]] = d.available ? d.value : -1; dm.brightness = b }
        else if (a[0] === "text") { var m = text.match(/text size: (\d+)/); if (m) dm.textSize = parseInt(m[1]) }
        dm.next()
      }
    }
    stderr: StdioCollector { waitForEnd: true; onStreamFinished: if (text.trim() && proc.args[0] !== "brightness") dm.error = text.trim().split("\n").pop() }
    onExited: function(code) { if (code === 127) dm.hasBackend = false; if (code === 0 && ["scale", "mode", "arrange"].indexOf(proc.args[0]) >= 0) dm.cmd(["state"]) }
  }
  function next() {
    if (proc.running || !queue.length) return
    proc.args = queue[0]; queue = queue.slice(1)
    proc.command = proc.args[0] === "text" ? ["omarchy", "display", "text", "size"].concat(proc.args.slice(1)) : [backend].concat(proc.args)
    proc.running = true
  }
  function cmd(args) {
    // a newer brightness for the same monitor replaces the queued one
    if (args[0] === "brightness" && args.length === 3) queue = queue.filter(function(q) { return !(q[0] === "brightness" && q[1] === args[1] && q.length === 3) })
    error = ""
    queue = queue.concat([args]); next()
  }
  function refresh() {
    cmd(["state"]); cmd(["text"])
    for (var i = 0; i < displays.length; i++) cmd(["brightness", displays[i].name])
  }
  onDisplaysChanged: { for (var i = 0; i < displays.length; i++) if (brightness[displays[i].name] === undefined) cmd(["brightness", displays[i].name]) }
  readonly property bool watching: active && notch !== null && notch.settingsOpen && notch.settingsSection === "displays"
  onWatchingChanged: if (watching) refresh()
}
