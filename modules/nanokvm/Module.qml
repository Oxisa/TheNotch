import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."
import "../../fonts"

// NanoKVM: NanoKVM-USB without the internet. The nanokvm-usb package (AUR)
// ships the browser version and a local server; bin/nanokvm starts the
// server, opens the KVM screen in its own Chromium window and stops the
// server when the window closes. The icon shows only while the package is
// installed. Same backend as omarchy-backup-hub's osia.nanokvm bar button.
NotchModule {
  id: kvm
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: "NanoKVM"
  icon: "\u{f0379}"
  description: t("Экран и клавиатура другого компьютера через NanoKVM-USB, без интернета",
                 "Another computer's screen and keyboard through NanoKVM-USB, offline")
  pageWidth: 420
  page: Component { NanoKvmPage { mod: kvm } }
  inRail: st.installed

  readonly property string bin: decodeURIComponent(Qt.resolvedUrl("bin/nanokvm").toString().replace(/^file:\/\//, ""))
  property var st: ({ installed: false, server: false, window: false })
  readonly property bool busy: actionProc.running

  Process {
    id: statusProc
    command: [kvm.bin, "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: { try { kvm.st = JSON.parse(text) } catch (e) {} }
    }
  }
  Process { id: actionProc; onExited: kvm.refresh() }
  function refresh() { if (!statusProc.running) statusProc.running = true }
  function run(action) {
    if (action === "open" && notch) notch.expanded = false
    actionProc.command = [bin, action]; actionProc.running = true
  }
  // often while the window is open or the notch is, rarely otherwise
  Timer {
    interval: kvm.st.window || (kvm.notch !== null && kvm.notch.expanded) ? 3000 : 15000
    repeat: true; triggeredOnStart: true; running: kvm.active
    onTriggered: kvm.refresh()
  }

  // the collapsed notch: a quiet KVM mark while the window is open
  live: st.window
  livePriority: 3
  liveLeft: Component { Text { text: "\u{f0379}"; color: Color.accent; font.family: Fonts.ui; font.pixelSize: Style.font.body } }
  liveRight: Component { Text { text: "KVM"; color: Color.foreground; font.family: Fonts.ui; font.pixelSize: Style.font.body; font.bold: true } }
}
