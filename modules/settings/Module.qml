import QtQuick
import "../.."

// TheNotch's own settings — a section of the settings window, not a
// dashboard: edge, the Omarchy bar, colour, language, which events to show.
NotchModule {
  id: mod
  title: notch && notch.lang === "ru" ? "Основные" : "General"
  icon: "\u{f0493}"
  inRail: false
  core: true
  sectionOrder: 0
  settingsPage: Component { SettingsPage { notch: mod.notch } }
}
