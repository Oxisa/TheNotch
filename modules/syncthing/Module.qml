import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."

// Syncthing: is it running, this computer's ID (to add it on another
// device), the folders with their state, the other devices — read from
// Syncthing's own local API (bin/syncctl). Changes stay in its web UI, one
// button away. After the Syncthing plugin (ilyazar) — the idea, not its code.
NotchModule {
  id: sy
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: "Syncthing"
  icon: "\u{f04e6}"
  description: t("Синхронизация папок между устройствами", "Folders kept in sync between devices")
  inRail: false
  settingsSection: "tools"
  sectionOrder: 2
  settingsPage: Component { SyncthingSettings { mod: sy } }
  readonly property string bin: decodeURIComponent(Qt.resolvedUrl("bin/syncctl").toString().replace(/^file:\/\//, ""))
  property var st: ({})
  Process { id: proc; command: [sy.bin]; stdout: StdioCollector { waitForEnd: true; onStreamFinished: { try { sy.st = JSON.parse(text) } catch (e) {} } } }
  readonly property bool watching: active && notch !== null && notch.settingsOpen && notch.settingsSection === "tools"
  Timer { interval: 5000; repeat: true; triggeredOnStart: true; running: sy.watching; onTriggered: if (!proc.running) proc.running = true }
  function start() { Quickshell.execDetached(["systemctl", "--user", "enable", "--now", "syncthing"]) }
}
