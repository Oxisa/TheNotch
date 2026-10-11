import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."

// Logitech mice (MX Master and other HID++ devices) through Solaar: battery,
// DPI, SmartShift, the wheel and the thumb wheel. bin/mousectl does the
// work; Solaar is slow, so the last state is cached and shown at once.
// After Omalogimouse (Ormus Solutions) — the idea, not its code.
NotchModule {
  id: ms
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Мышь Logitech", "Logitech mouse")
  icon: "\u{f037d}"
  description: t("Чувствительность, SmartShift, колёса и заряд мыши Logitech", "Sensitivity, SmartShift, wheels and battery of a Logitech mouse")
  inRail: false
  settingsSection: "bluetooth"
  sectionOrder: 3
  settingsPage: Component { MouseSettings { mod: ms } }

  readonly property string bin: decodeURIComponent(Qt.resolvedUrl("bin/mousectl").toString().replace(/^file:\/\//, ""))
  property var devices: []
  property bool loading: false
  property string error: ""
  FileView {
    id: cache
    path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/thenotch-mouse.json"
    printErrors: false
    onLoaded: { try { ms.devices = JSON.parse(text()).devices || [] } catch (e) {} }
  }
  Process {
    id: proc
    property var args: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var d = JSON.parse(text)
          if (proc.args[0] === "state") ms.devices = d.devices || []
          else { ms.error = d.ok ? "" : d.error; if (d.ok) Qt.callLater(ms.refresh) }
        } catch (e) {}
        ms.loading = false; ms.next()
      }
    }
  }
  property var queue: []
  function next() {
    if (proc.running || !queue.length) return
    proc.args = queue[0]; queue = queue.slice(1)
    loading = proc.args[0] === "state"
    proc.command = [bin].concat(proc.args); proc.running = true
  }
  function cmd(args) { queue = queue.concat([args]); next() }
  function refresh() { cmd(["state"]) }
  function set(name, key, value) {
    // show it at once; Solaar takes its time
    devices = devices.map(function(d) { if (d.name !== name) return d; var s = Object.assign({}, d.settings); s[key] = value; return Object.assign({}, d, { settings: s }) })
    cmd(["set", name, key, String(value)])
  }
  readonly property bool watching: active && notch !== null && notch.settingsOpen && notch.settingsSection === "bluetooth"
  onWatchingChanged: if (watching) { cache.reload(); refresh() }
}
