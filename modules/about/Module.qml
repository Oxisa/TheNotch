import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."

// About: this computer the way fastfetch shows it — Omarchy's logo in the
// theme's colour, the facts beside it, memory and disks as bars, the theme's
// palette — with a copy button. The credits sit next to it.
NotchModule {
  id: ab
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Этот компьютер", "This computer")
  icon: "\u{f0aab}"
  description: t("Сведения о системе", "System information")
  inRail: false
  core: true
  settingsSection: "system"
  sectionOrder: 20
  settingsPage: Component { AboutPage { mod: ab } }
  // what fastfetch knows, as JSON (bin/sysinfo)
  property var info: ({})
  readonly property string bin: decodeURIComponent(Qt.resolvedUrl("bin/sysinfo").toString().replace(/^file:\/\//, ""))
  Process {
    id: proc
    command: [ab.bin]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: { try { ab.info = JSON.parse(text) } catch (e) {} } }
  }
  function load() { if (!proc.running) proc.running = true }
}
