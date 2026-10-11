import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."

// Account: your picture (~/.face, shown on Home and used by the lock screen
// and other apps) and the name the shell greets you with.
NotchModule {
  id: ac
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Учётная запись", "Account")
  icon: "\u{f0009}"
  description: t("Аватар и имя", "Picture and name")
  inRail: false
  core: true
  settingsSection: "account"
  sectionOrder: 1
  settingsPage: Component { AccountSettings { mod: ac } }
  function opt(key, fallback) { return notch ? notch.moduleOpt("account", key, fallback) : fallback }
  function persist(values) { if (notch) notch.modulePersist("account", values) }

  readonly property string user: Quickshell.env("USER") || ""
  readonly property string displayName: String(opt("name", "")) || user
  // bumps whenever the picture changes, so Images reload it
  property int faceRev: 0
  readonly property string face: "file://" + Quickshell.env("HOME") + "/.face?" + faceRev
  readonly property string bin: decodeURIComponent(Qt.resolvedUrl("bin/avatar").toString().replace(/^file:\/\//, ""))
  Process { id: proc; onExited: ac.faceRev++ }
  function run(args) { if (!proc.running) { proc.command = [bin].concat(args); proc.running = true } }

  // the system file chooser opens under the settings window: close it first,
  // and come back to this section when the chooser is done
  Process {
    id: picker
    onExited: { ac.faceRev++; if (ac.notch) ac.notch.openSettings("account") }
  }
  function pickFile() {
    if (notch) notch.settingsOpen = false
    picker.command = [bin, "pick"]; picker.running = true
  }
}
