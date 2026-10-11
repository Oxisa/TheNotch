import QtQuick
import "../.."
import "../../../osia.soundhub" as SH

// Settings → Sound → Microphone: the same page as the notch's Sound →
// Microphone tab (device, test, voice processing).
NotchModule {
  id: m
  readonly property var host: notch ? notch.moduleById("soundhub") : null
  title: notch && notch.lang === "ru" ? "Микрофон" : "Microphone"
  icon: "\u{f036c}"
  inRail: false
  core: true                               // part of Sound, not a module of its own
  settingsSection: "sound"
  sectionOrder: 20
  readonly property bool hostOn: host !== null && host.active
  settingsPage: Component { SH.MicPage { host: m.host } }
}
