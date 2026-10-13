import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import qs.Commons
import "../.."

// Bluetooth & devices: Bluetooth (power, nearby devices, pair, connect,
// forget, batteries), printers (CUPS), cameras (V4L2 with a preview), and a
// "Batteries" desktop widget like macOS's — a ring with the device's glyph
// and its charge. Bluetooth comes live from BlueZ (Quickshell.Bluetooth);
// bin/devctl reads UPower batteries, printers and cameras. After Omarchy's Bluetooth panel,
// Omagic and the Sony/Logitech plugins — ideas only, no code taken.
NotchModule {
  id: dv
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Устройства", "Devices")
  icon: "\u{f00af}"
  description: t("Bluetooth и принтеры; заряд — в виджете «Батареи»", "Bluetooth and printers; charge is in the Batteries widget")
  inRail: false
  settingsSection: "bluetooth"
  sectionOrder: 1
  settingsPage: Component { DevicesSettings { mod: dv } }
  function opt(key, fallback) { return notch ? notch.moduleOpt("devices", key, fallback) : fallback }
  function persist(values) { if (notch) notch.modulePersist("devices", values) }

  readonly property string bin: decodeURIComponent(Qt.resolvedUrl("bin/devctl").toString().replace(/^file:\/\//, ""))
  // Bluetooth is live from BlueZ (Quickshell.Bluetooth: events, no
  // bluetoothctl); devctl still reads what BlueZ doesn't know — UPower
  // batteries, printers, cameras ("status --no-bt", fast).
  property var raw: ({ batteries: [], printers: { list: [], jobs: [] }, cameras: [] })
  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property var kinds: ({ "audio-headset": "headphones", "audio-headphones": "headphones", "audio-card": "speaker",
                                  "input-mouse": "mouse", "input-keyboard": "keyboard", "input-gaming": "gamepad", "input-tablet": "tablet",
                                  "phone": "phone", "computer": "computer", "camera-video": "camera", "printer": "printer" })
  readonly property var btDevices: {
    var ds = Bluetooth.devices ? Bluetooth.devices.values : []
    return ds.map(function(d) {
      return { mac: d.address, name: d.name || d.deviceName || d.address, kind: dv.kinds[d.icon] || "other", icon: d.icon,
               paired: d.paired || d.bonded, connected: d.connected, trusted: d.trusted,
               battery: d.batteryAvailable ? Math.round(d.battery * 100) : null }
    }).sort(function(a, b) { return (b.connected - a.connected) || (b.paired - a.paired) || a.name.toLowerCase().localeCompare(b.name.toLowerCase()) })
  }
  readonly property var st: ({
    bt: { present: adapter !== null, powered: !!(adapter && adapter.enabled), discovering: !!(adapter && adapter.discovering), name: adapter ? adapter.name : "" },
    devices: btDevices,
    // Bluetooth batteries UPower doesn't list come from BlueZ
    batteries: (raw.batteries || []).concat(btDevices.filter(function(d) { return d.connected && d.battery !== null && !(raw.batteries || []).some(function(b) { return b.name === d.name }) })
                                                      .map(function(d) { return { name: d.name, kind: d.kind, percent: d.battery, charging: false } })),
    printers: raw.printers || { list: [], jobs: [] },
    cameras: raw.cameras || []
  })
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
          if (proc.args[0] === "status") dv.raw = d
          else if (proc.args[1] === "discover") dv.found = d.found || []
          else { dv.error = d.ok ? "" : (d.error || ""); dv.cmd(["status", "--no-bt"]) }
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
  function device(mac) { var ds = Bluetooth.devices ? Bluetooth.devices.values : []; for (var i = 0; i < ds.length; i++) if (ds[i].address === mac) return ds[i]; return null }
  function bt(action, mac) {
    error = ""
    if (action === "power") { if (adapter) adapter.enabled = mac === "on"; return }
    var d = device(mac)
    if (!d) { error = t("Устройство не найдено", "Device not found"); return }
    if (action === "connect") { if (!d.paired && !d.bonded) { d.trusted = true; d.pair() } else d.connect() }
    else if (action === "disconnect") d.disconnect()
    else if (action === "remove") d.forget()
    else if (action === "trust") d.trusted = true
  }
  function scan() { if (adapter) { adapter.enabled = true; adapter.discovering = true }; scanning = true; scanEnd.restart() }
  property bool scanning: false
  property var found: []                         // network printers not yet added
  Timer { id: scanEnd; interval: 16000; onTriggered: { dv.scanning = false; if (dv.adapter) dv.adapter.discovering = false } }

  readonly property bool watching: active && notch !== null && notch.settingsOpen && notch.settingsSection === "bluetooth"
  // only the non-Bluetooth part is polled (Bluetooth arrives by itself)
  Timer { interval: dv.watching ? 10000 : 120000; repeat: true; triggeredOnStart: true
          running: dv.watching || (dv.active && dv.deskEnabled); onTriggered: dv.cmd(["status", "--no-bt"]) }

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
