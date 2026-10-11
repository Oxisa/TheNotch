import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."

// Network & internet: the connection (wired or Wi-Fi) with its speed and
// latency, Wi-Fi networks (join, forget, share by QR), wired adapters,
// tunnels (shown, never switched — their apps own them), and in Advanced the
// addresses, DNS and saved connections. NetworkManager does the work through
// bin/netctl. Two desktop widgets: a card and a signal ring. Wi-Fi list and
// details after Network+ (das6ng) and Omarchy's own network panel — ideas
// only, no code taken.
NotchModule {
  id: nw
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Сеть", "Network")
  icon: "\u{f059f}"
  description: t("Интернет, Wi-Fi, проводная сеть и туннели — настройки и виджеты", "Internet, Wi-Fi, wired network and tunnels — settings and widgets")
  inRail: false
  settingsSection: "network"
  sectionOrder: 1
  settingsPage: Component { NetworkSettings { mod: nw } }
  function opt(key, fallback) { return notch ? notch.moduleOpt("network", key, fallback) : fallback }
  function persist(values) { if (notch) notch.modulePersist("network", values) }

  readonly property string bin: decodeURIComponent(Qt.resolvedUrl("bin/netctl").toString().replace(/^file:\/\//, ""))
  property var st: ({ devices: [], tunnels: [], wifiRadio: false, primary: null })
  property var networks: []
  property var saved: []
  property var latency: ({})
  property string error: ""
  property string busy: ""                       // what is running, for spinners
  property var queue: []
  Process {
    id: proc
    property var args: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var a = proc.args, d = null
        try { d = JSON.parse(text) } catch (e) {}
        nw.busy = ""
        if (d) {
          if (a[0] === "status") nw.st = d
          else if (a[0] === "wifi") nw.networks = d.networks || []
          else if (a[0] === "saved") nw.saved = d.saved || []
          else if (a[0] === "ping") nw.latency = d
          else if (a[0] === "qr") nw.qr = d.ok ? { ssid: d.ssid, url: "file://" + d.path + "?" + Date.now() } : null
          else {
            nw.error = d.ok ? "" : (d.error || "")
            nw.refresh()
          }
        }
        nw.next()
      }
    }
  }
  function next() {
    if (proc.running || !queue.length) return
    proc.args = queue[0]; queue = queue.slice(1)
    busy = proc.args[0] === "connect" ? "connect:" + proc.args[1] : proc.args[0]
    proc.command = [bin].concat(proc.args); proc.running = true
  }
  function cmd(args) {
    for (var i = 0; i < queue.length; i++) if (JSON.stringify(queue[i]) === JSON.stringify(args)) return
    queue = queue.concat([args]); next()
  }
  function refresh() { cmd(["status"]); if (st.wifiRadio) cmd(["wifi"]); cmd(["saved"]) }
  function connect(ssid, password) { error = ""; cmd(password ? ["connect", ssid, password] : ["connect", ssid]) }
  function setRadio(on) { cmd(["radio", on ? "on" : "off"]) }
  property var qr: null

  // poll: often while settings are open, rarely for the widgets
  readonly property bool watching: active && notch !== null && notch.settingsOpen && notch.settingsSection === "network"
  readonly property bool widgetsOn: active && (deskEnabled || opt("ringWidget", false) === true)
  Timer { interval: nw.watching ? 4000 : 20000; repeat: true; triggeredOnStart: true; running: nw.watching || nw.widgetsOn; onTriggered: nw.refresh() }
  Timer { interval: 30000; repeat: true; triggeredOnStart: true; running: nw.watching || nw.widgetsOn; onTriggered: nw.cmd(["ping"]) }

  // ----------------------------------------------------------- speed
  property real down: 0
  property real up: 0
  property var history: []
  property var last: null
  FileView { id: netdev; path: "/proc/net/dev"; printErrors: false }
  Timer {
    interval: 1000; repeat: true; running: nw.watching || nw.widgetsOn
    onTriggered: {
      netdev.reload()
      var dev = nw.st.primary ? nw.st.primary.device : "", lines = netdev.text().split("\n")
      for (var i = 0; i < lines.length; i++) {
        var p = lines[i].trim().split(/[:\s]+/)
        if (p[0] !== dev) continue
        var rx = Number(p[1]), tx = Number(p[9]), now = Date.now()
        if (nw.last && nw.last.dev === dev) {
          var dt = (now - nw.last.t) / 1000
          nw.down = Math.max(0, (rx - nw.last.rx) / dt); nw.up = Math.max(0, (tx - nw.last.tx) / dt)
          var h = nw.history.slice(-59); h.push({ down: nw.down, up: nw.up }); nw.history = h
        }
        nw.last = { dev: dev, rx: rx, tx: tx, t: now }
      }
    }
  }
  function rate(b) {
    if (b >= 2 ** 20) return (b / 2 ** 20).toFixed(1) + t(" МБ/с", " MB/s")
    if (b >= 1024) return Math.round(b / 1024) + t(" КБ/с", " KB/s")
    return Math.round(b) + t(" Б/с", " B/s")
  }

  // --------------------------------------------------------- summaries
  readonly property var primary: st.primary
  readonly property bool online: primary !== null
  readonly property bool onWifi: online && primary.type === "wifi"
  function wifiGlyph(signal) {
    return signal >= 75 ? "\u{f0928}" : signal >= 50 ? "\u{f0925}" : signal >= 25 ? "\u{f0922}" : "\u{f091f}"
  }
  readonly property string glyph: !online ? "\u{f0319}" : onWifi ? wifiGlyph(primary.signal || 0) : "\u{f0200}"
  readonly property string name: !online ? t("Нет подключения", "Offline")
                                 : onWifi ? (primary.ssid || primary.connection) : t("Кабель", "Wired")
  readonly property string sub: !online ? "" : onWifi ? (primary.signal || 0) + "% · " + (primary.rate || "")
                                : (primary.speed ? (primary.speed >= 1000 ? primary.speed / 1000 + t(" Гбит/с", " Gb/s") : primary.speed + t(" Мбит/с", " Mb/s")) : "")
  readonly property var activeTunnels: (st.tunnels || []).filter(function(x) { return x.up })

  // ----------------------------------------------------------- widgets
  widgetTitle: t("Сеть", "Network")
  widgetIcon: "\u{f059f}"
  deskEnabled: opt("widget", false) === true
  function setDeskEnabled(on) { persist({ widget: on }) }
  deskDefault: ({ x: 0.04, y: 0.62 })
  deskWidget: Component { NetworkCard { mod: nw } }
  deskList: [
    DeskWidget {
      wid: "netring"
      title: nw.t("Сеть: кольцо", "Network ring")
      icon: "\u{f0928}"
      component: Component { NetworkRing { mod: nw } }
      enabled: nw.opt("ringWidget", false) === true
      defaultPos: ({ x: 0.16, y: 0.62 })
      onToggled: function(on) { nw.persist({ ringWidget: on }) }
    }
  ]
  widgetPage: Component { NetworkWidgetSettings { mod: nw } }
}
