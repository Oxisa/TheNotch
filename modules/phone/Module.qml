import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."

// Phone: show an iPhone's (or iPad's, Mac's) screen on this computer — an
// AirPlay receiver, UxPlay (FDH2/UxPlay, GPL-3.0), run by the shell while
// you want it, built for this user by bin/install-uxplay. Optional PIN,
// full screen. While mirroring, the collapsed notch says so.
NotchModule {
  id: ph
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Телефон", "Phone")
  icon: "\u{f011c}"
  description: t("Экран iPhone на компьютере по AirPlay", "An iPhone's screen on this computer over AirPlay")
  inRail: false
  settingsSection: "bluetooth"
  sectionOrder: 5
  settingsPage: Component { PhoneSettings { mod: ph } }
  function opt(key, fallback) { return notch ? notch.moduleOpt("phone", key, fallback) : fallback }
  function persist(values) { if (notch) notch.modulePersist("phone", values) }

  readonly property string uxplay: Quickshell.env("HOME") + "/.local/bin/uxplay"
  readonly property string installer: decodeURIComponent(Qt.resolvedUrl("bin/install-uxplay").toString().replace(/^file:\/\//, ""))
  property bool installed: true
  FileView { path: ph.uxplay; printErrors: false; onLoadFailed: ph.installed = false; onLoaded: ph.installed = true }
  readonly property string name: String(opt("name", "")) || (Quickshell.env("HOSTNAME") || "Omarchy")
  readonly property string pin: String(opt("pin", ""))

  property string status: "off"                  // off | waiting | mirroring
  property string client: ""
  Process {
    id: rx
    command: [ph.uxplay, "-n", ph.name, "-nh", "-p"]
             .concat(ph.pin.length === 4 ? ["-pin" + ph.pin] : [])
             .concat(ph.opt("fullscreen", false) === true ? ["-fs"] : [])
             .concat(ph.opt("audio", true) === false ? ["-vsync", "no", "-as", "0"] : [])
    stdout: SplitParser { onRead: function(l) { ph.parse(l) } }
    stderr: SplitParser { onRead: function(l) { ph.parse(l) } }
    onRunningChanged: ph.status = running ? "waiting" : "off"
  }
  function parse(l) {
    if (/connection request from|Accepted IPv[46] connection|raop_rtp_mirror|start video/i.test(l)) status = "mirroring"
    var m = l.match(/[Cc]lient (?:name|identified as)[: ]+(.+)/); if (m) client = m[1]
    if (/Connection closed|teardown|Stopped mirror/i.test(l)) { status = rx.running ? "waiting" : "off"; client = "" }
  }
  function start() { if (!rx.running) rx.running = true }
  function stop() { rx.running = false }
  property bool installing: false
  Process {
    id: inst
    command: ["bash", "-c", "\"$0\" >\"${XDG_RUNTIME_DIR:-/tmp}/thenotch-uxplay-install.log\" 2>&1", ph.installer]
    onExited: function(code) { ph.installing = false; ph.installed = code === 0 }
  }
  function install() { installing = true; inst.running = true }
  Component.onDestruction: rx.running = false

  live: status === "mirroring"
  livePriority: 25
  liveLeft: Component { Text { text: "\u{f011c}"; color: Color.accent; font.family: Style.font.family; font.pixelSize: Style.font.body + 2 } }
  liveRight: Component { Text { text: ph.t("Повтор экрана", "Mirroring"); color: Color.foreground; font.family: Style.font.family; font.pixelSize: Style.font.caption + 1; font.bold: true } }
}
