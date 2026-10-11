import QtQuick
import "../.."
import "../settings"

// The notch itself in Settings → Personalisation: which monitor and edge,
// whether the Omarchy bar hides, its colour.
NotchModule {
  id: nl
  title: notch && notch.lang === "ru" ? "Чёлка" : "Notch"
  icon: "\u{f0493}"
  inRail: false
  core: true
  settingsSection: "personal"
  sectionOrder: 0
  settingsPage: Component { SettingsPage { notch: nl.notch; part: "notch" } }
}
