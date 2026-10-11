import QtQuick
import "../.."
import "../../../osia.soundhub" as SH

// Settings → Sound → Equalizer: the same page as the notch's Sound → EQ tab.
NotchModule {
  id: m
  readonly property var host: notch ? notch.moduleById("soundhub") : null
  title: notch && notch.lang === "ru" ? "Эквалайзер" : "Equalizer"
  icon: "󰺢"
  inRail: false
  core: true                               // part of Sound, not a module of its own
  settingsSection: "sound"
  sectionOrder: 30
  settingsPage: Component { SH.EqPage { host: m.host } }
}
