import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."

// Bluetooth & devices: Bluetooth (power, nearby devices, pair, connect,
// forget, batteries), printers (CUPS), cameras (V4L2 with a preview), and a
// "Batteries" desktop widget like macOS's — a ring with the device's glyph
// and its charge. bin/devctl does the work. After Omarchy's Bluetooth panel,
// Omagic and the Sony/Logitech plugins — ideas only, no code taken.
NotchModule {
  id: dv
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Устройства", "Devices")
  icon: "\u{f00af}"
  description: t("Bluetooth, батареи устройств, принтеры и камеры", "Bluetooth, device batteries, printers and cameras")
  inRail: false
  settingsSection: "bluetooth"
  sectionOrder: 1
  settingsPage: Component { DevicesSettings { mod: dv } }
  function opt(key, fallback) { return notch ? notch.moduleOpt("devices", key, fallback) : fallback }
  function persist(values) { if (notch) notch.modulePersist("devices", values) }

  readonly property string bin: decodeURIComponent(Qt.resolvedUrl("bin/devctl").toString().replace(/^file:\/\//, ""))
  property var st: ({ bt: {}, devices: [], batteries: [], printers: { list: [], jobs: [] }, cameras: [] })
  property string busy: ""
  property string error: ""
  property var queue: []
  Process {
    id: proc
    property var args: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var d = null
        try { d = JSON.parse(text) } catch (e) {}
        dv.busy = ""
        if (d) {
          if (proc.args[0] === "status") dv.st = d
          else if (proc.args[1] === "discover") dv.found = d.found || []
          else { dv.error = d.ok ? "" : (d.error || ""); dv.cmd(["status"]) }
        }
        dv.next()
      }
    }
  }
  function next() {
    if (proc.running || !queue.length) return
    proc.args = queue[0]; queue = queue.slice(1)
    busy = proc.args.join(" ")
    proc.command = [bin].concat(proc.args); proc.running = true
  }
  function cmd(args) {
    for (var i = 0; i < queue.length; i++) if (JSON.stringify(queue[i]) === JSON.stringify(args)) return
    queue = queue.concat([args]); next()
  }
  function bt(action, mac) { error = ""; cmd(["bt", action, mac]) }
  function scan() { cmd(["bt", "scan", "15"]); scanning = true; scanEnd.restart() }
  property bool scanning: false
  property var found: []                         // network printers not yet added
  Timer { id: scanEnd; interval: 16000; onTriggered: dv.scanning = false }

  readonly property bool watching: active && notch !== null && notch.settingsOpen && notch.settingsSection === "bluetooth"
  Timer { interval: dv.watching ? (dv.scanning ? 2000 : 4000) : 60000; repeat: true; triggeredOnStart: true
          running: dv.watching || (dv.active && dv.deskEnabled); onTriggered: dv.cmd(["status"]) }

  function glyph(kind) {
    switch (kind) {
      case "headphones": return "\u{f02cb}"
      case "speaker": return "\u{f04c3}"
      case "mouse": return "\u{f037d}"
      case "keyboard": return "\u{f030c}"
      case "gamepad": return "\u{f05ba}"
      case "phone": return "\u{f011c}"
      case "tablet": return "\u{f04f7}"
      case "computer": return "\u{f0322}"
      case "camera": return "\u{f05a0}"
      case "printer": return "\u{f042a}"
    }
    return "\u{f00af}"
  }

  // ---------------------------------------------------------- widget
  widgetTitle: t("Батареи", "Batteries")
  widgetIcon: "\u{f0079}"
  deskEnabled: opt("widget", false) === true
  function setDeskEnabled(on) { persist({ widget: on }) }
  deskDefault: ({ x: 0.04, y: 0.72 })
  deskWidget: Component { BatteryWidget { mod: dv } }
  widgetPage: Component { BatteryWidgetSettings { mod: dv } }
}
