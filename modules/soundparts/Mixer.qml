import QtQuick
import "../.."
import "../../vendor/soundhub" as SH

// Settings → Sound → Mixer: SoundHub's mixer (sources, mixes, outputs,
// presets) — moved here from the notch, where it was too big.
NotchModule {
  id: m
  readonly property var host: notch ? notch.moduleById("soundhub") : null
  title: notch && notch.lang === "ru" ? "Микшер" : "Mixer"
  icon: "\u{f1542}"
  inRail: false
  core: true                               // part of Sound, not a module of its own
  settingsSection: "sound"
  sectionOrder: 15
  settingsPage: Component { SH.MixerPage { host: m.host } }
}
