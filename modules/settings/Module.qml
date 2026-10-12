import QtQuick
import "../.."

// TheNotch's own settings, split over the settings window: the language
// here (System); the notch's place and look (notchlook, Personalisation);
// which events show (notifications, System).
NotchModule {
  id: mod
  title: notch && notch.lang === "ru" ? "Оболочка" : "Shell"
  icon: "\u{f05ca}"
  inRail: false
  core: true
  sectionOrder: 0
  settingsSection: "system"
  settingsPage: Component { SettingsPage { notch: mod.notch; part: "system" } }
}
