import QtQuick
import "../.."
import "../settings"

// The notch itself in Settings → Personalisation: what it shows where
// (SlotEditor), which monitor and edge, its colour.
NotchModule {
  id: nl
  title: notch && notch.lang === "ru" ? "Чёлка" : "Notch"
  icon: "\u{f0493}"
  inRail: false
  core: true
  settingsSection: "personal"
  sectionOrder: 0
  settingsPage: Component {
    Column {
      spacing: 12
      SlotEditor { width: parent.width; notch: nl.notch }
      SettingsPage { width: parent.width; notch: nl.notch; part: "notch" }
    }
  }
}
