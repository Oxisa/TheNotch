import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs.Commons
import "../.."

// Network & internet: the connection (wired or Wi-Fi) with its speed and
// latency, Wi-Fi networks (join, forget, share by QR), wired adapters,
// tunnels (shown, never switched — their apps own them), and in Details the
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
  description: t("Интернет, Wi-Fi, проводная сеть, трафик — настройки и виджеты", "Internet, Wi-Fi, wired network, traffic — settings and widgets")
  inRail: false
  settingsSection: "network"
  sectionOrder: 1
  settingsPage: Component { NetworkSettings { mod: nw } }
  function opt(key, fallback) { return notch ? notch.moduleOpt("network", key, fallback) : fallback }
  function persist(values) { if (notch) notch.modulePersist("network", values) }

  readonly property string bin: decodeURIComponent(Qt.resolvedUrl("bin/netctl").toString().replace(/^file:\/\//, ""))
  property var st: ({ devices: [], tunnels: [], wifiRadio: false, primary: null })
  // Wi-Fi comes live from NetworkManager (Quickshell.Networking): the list,
  // signal, saved/connected, connecting — no nmcli runs. netctl keeps what
  // the API doesn't give: addresses, DNS, tunnels, latency, wired profiles.
  readonly property var wifiDev: { var ds = Networking.devices ? Networking.devices.values : []; for (var i = 0; i < ds.length; i++) if (ds[i].type === DeviceType.Wifi) return ds[i]; return null }
  property bool wantScan: false                  // a Wi-Fi list is on screen (Settings or Centre)
  Binding { target: nw.wifiDev; property: "scannerEnabled"; value: nw.active && nw.wifiOn && (nw.watching || nw.wantScan); when: nw.wifiDev !== null }
  readonly property bool wifiOn: !!(Networking.wifiEnabled && Networking.wifiHardwareEnabled)
  readonly property var networks: {
    if (!wifiDev || !wifiOn) return []
    var best = {}, ns = wifiDev.networks ? wifiDev.networks.values : []
    for (var i = 0; i < ns.length; i++) {
      var n = ns[i]; if (!n.name) continue
      var o = { ssid: n.name, signal: Math.round(Math.max(0, Math.min(1, n.signalStrength)) * 100), active: n.connected, saved: n.known,
                secure: n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe, net: n }
      if (!best[o.ssid] || o.active || (o.signal > best[o.ssid].signal && !best[o.ssid].active)) best[o.ssid] = o
    }
    return Object.keys(best).map(function(k) { return best[k] }).sort(function(a, b) { return (b.active - a.active) || (b.signal - a.signal) })
  }
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
  function refresh() { cmd(["status"]); cmd(["saved"]) }
  // a Wi-Fi network: straight through NetworkManager; anything else (a saved
  // wired profile) through netctl
  function connect(ssid, password) {
    error = ""
    var hit = networks.filter(function(x) { return x.ssid === ssid })[0]
    if (hit && hit.net) { if (password) hit.net.connectWithPsk(password); else hit.net.connect(); after.restart(); return }
    cmd(password ? ["connect", ssid, password] : ["connect", ssid])
  }
  function setRadio(on) { Networking.wifiEnabled = on; after.restart() }
  Timer { id: after; interval: 1500; onTriggered: nw.refresh() }
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
  // one network widget, two looks: the card or the ring (Settings → Widgets)
  readonly property string deskLook: String(opt("look", "card"))
  deskWidget: Component {
    Loader {
      property bool editing: false
      property bool deskVertical: false
      property var deskStyle: ({})
      property real deskScale: 1
      readonly property bool deskShown: item ? item.deskShown !== false : false
      function feed() {
        if (!item) return
        item.editing = editing
        if ("deskVertical" in item) item.deskVertical = deskVertical
        if ("deskStyle" in item) item.deskStyle = deskStyle
        if ("deskScale" in item) item.deskScale = deskScale
      }
      onEditingChanged: feed()
      onDeskVerticalChanged: feed()
      onDeskStyleChanged: feed()
      onDeskScaleChanged: feed()
      onLoaded: feed()
      sourceComponent: nw.deskLook === "ring" ? ringLook : cardLook
    }
  }
  Component { id: cardLook; NetworkCard { mod: nw } }
  Component { id: ringLook; NetworkRing { mod: nw } }
  // the ring used to be a widget of its own: fold it into this one
  property bool migrated: false
  readonly property bool canMigrate: notch !== null && notch.settingsLoaded
  onCanMigrateChanged: if (canMigrate && !migrated) {
    migrated = true
    if (opt("ringWidget", false) === true) persist(deskEnabled ? { ringWidget: false } : { widget: true, look: "ring", ringWidget: false })
  }
  widgetPage: Component { NetworkWidgetSettings { mod: nw } }
}
