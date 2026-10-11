import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."

// Sony headphones (WH-1000XM6 and other MDR v2 models): noise control, the
// headphones' own equalizer, DSEE, listening mode, auto pause and power,
// multipoint. Talks to mdrctld — delarosa1312/omarchy-sony-xm5 (MIT) over
// libmdr from mos9527/SonyHeadphonesClient (MIT) — installed for this user by
// ../devices/bin/install-sony (no root). State comes from the daemon's file.
NotchModule {
  id: hp
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Наушники", "Headphones")
  icon: "\u{f02cb}"
  description: t("Шумоподавление, эквалайзер и настройки наушников Sony", "Noise control, equalizer and settings of Sony headphones")
  inRail: false
  settingsSection: "bluetooth"
  sectionOrder: 2
  settingsPage: Component { HeadphonesSettings { mod: hp } }

  readonly property string home: Quickshell.env("HOME")
  readonly property string ctl: home + "/.local/share/thenotch/mdrctl/bin/mdrctl"
  readonly property string installer: decodeURIComponent(Qt.resolvedUrl("../devices/bin/install-sony").toString().replace(/^file:\/\//, ""))
  property bool installed: true
  property var st: ({})
  readonly property bool present: !!(st.present && st.session)
  FileView {
    id: state
    path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/mdrctl/state.json"
    printErrors: false
    watchChanges: true
    onLoaded: { try { hp.st = JSON.parse(text()) } catch (e) {} }
    onFileChanged: reload()
    onLoadFailed: hp.st = ({})
  }
  // the daemon renames the file into place; a watch can miss that
  Timer { interval: 2500; repeat: true; running: hp.active; onTriggered: state.reload() }

  property string error: ""
  property var queue: []
  Process {
    id: proc
    stderr: StdioCollector { waitForEnd: true; onStreamFinished: hp.error = text.trim() }
    onExited: function(code) { if (code === 0) hp.error = ""; if (code === 127 || code === 126) hp.installed = false; state.reload(); hp.next() }
  }
  function next() {
    if (proc.running || !queue.length) return
    proc.command = [ctl].concat(queue[0]); queue = queue.slice(1); proc.running = true
  }
  function cmd(args) { queue = queue.concat([args]); next() }

  // install the daemon (builds libmdr, a couple of minutes)
  property bool installing: false
  Process {
    id: inst
    command: ["bash", "-c", "\"$0\" >\"${XDG_RUNTIME_DIR:-/tmp}/thenotch-sony-install.log\" 2>&1", hp.installer]
    onExited: function(code) { hp.installing = false; hp.installed = code === 0; hp.error = code === 0 ? "" : hp.t("Не удалось установить, см. thenotch-sony-install.log", "Install failed, see thenotch-sony-install.log") }
  }
  function install() { installing = true; inst.running = true }
  FileView { id: probe; path: hp.ctl; printErrors: false; onLoadFailed: hp.installed = false; onLoaded: hp.installed = true }

  readonly property string mode: st.mode || "off"
  function modeName(m) { return { cancelling: t("Шумоподавление", "Noise cancelling"), ambient: t("Окружение", "Ambient sound"), off: t("Выключено", "Off") }[m] || m }
  function modeIcon(m) { return { cancelling: "\u{f02cb}", ambient: "\u{f07c5}", off: "\u{f07ce}" }[m] || "\u{f02cb}" }
}
