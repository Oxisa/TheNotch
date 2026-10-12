import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."
import "../../fonts"

// Phone: KDE Connect through the kcd daemon (bethropolis/kcd, which the
// OMAConnect plugin by ekollof also uses) — the paired phone, its battery,
// ping, "find my phone", send a file or the clipboard, pair / unpair. The
// phone's own notifications reach the notch through kcd's notifications.
// Works with the KDE Connect app on Android and iOS.
NotchModule {
  id: ph
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Телефон", "Phone")
  icon: "\u{f011c}"
  description: t("Телефон через KDE Connect: батарея, файлы, буфер, поиск", "The phone over KDE Connect: battery, files, clipboard, find it")
  inRail: false
  settingsSection: "bluetooth"
  sectionOrder: 5
  settingsPage: Component { PhoneSettings { mod: ph } }

  readonly property string bin: decodeURIComponent(Qt.resolvedUrl("bin/phonectl").toString().replace(/^file:\/\//, ""))
  property var st: ({ daemon: true, devices: [] })
  property string busy: ""
  property var queue: []
  Process {
    id: proc
    property var args: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var d = null
        try { d = JSON.parse(text) } catch (e) {}
        if (proc.args[0] === "state") { if (d) ph.st = d }
        else {
          if (d && !d.ok && ph.notch) ph.notch.flash({ key: "phone", icon: "\u{f011c}", title: ph.t("Телефон", "Phone"), message: ph.t("Не ответил — откройте KDE Connect на телефоне", "No answer — open KDE Connect on the phone") })
          ph.busy = ""
          ph.queue = ph.queue.concat([["state"]])
        }
        ph.next()
      }
    }
  }
  function next() {
    if (proc.running || !queue.length) return
    proc.args = queue[0]; queue = queue.slice(1)
    if (proc.args[0] !== "state") busy = proc.args[0]
    proc.command = [bin].concat(proc.args); proc.running = true
  }
  function cmd(args) { queue = queue.concat([args]); next() }
  readonly property bool watching: active && notch !== null && notch.settingsOpen && notch.settingsSection === "bluetooth"
  Timer { interval: ph.watching ? 8000 : 60000; repeat: true; triggeredOnStart: true; running: ph.active; onTriggered: ph.cmd(["state"]) }

  // a file to the phone: the system file chooser, then kcd share
  property string shareTo: ""
  function shareFile(id) { shareTo = id; if (!pick.running) pick.running = true }
  Process {
    id: pick
    command: ["omarchy-file-select", "--title", ph.t("Отправить на телефон", "Send to the phone"), "--multiple"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: String(text).trim().split("\n").filter(function(f) { return f }).forEach(function(f) { ph.cmd(["share", ph.shareTo, f]) }) }
  }

  // connected / gone: a word in the notch
  property var wasConnected: ({})
  onStChanged: {
    var now = {}
    ;(st.devices || []).forEach(function(d) {
      now[d.id] = d.connected
      if (notch && wasConnected[d.id] !== undefined && wasConnected[d.id] !== d.connected)
        notch.flash({ key: "phone-" + d.id, icon: "\u{f011c}", title: d.name, message: d.connected ? t("на связи", "connected") : t("отключился", "disconnected"), ms: 3000 })
    })
    wasConnected = now
  }
}
