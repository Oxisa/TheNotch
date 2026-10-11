import QtQuick
import "../.."

// Settings → Modules: switch each part of the notch on or off.
NotchModule {
  id: mm
  title: notch && notch.lang === "ru" ? "Модули" : "Modules"
  icon: "\u{f0431}"
  inRail: false
  core: true
  sectionOrder: 1
  settingsSection: "modules"
  settingsPage: Component { ModulesPage { notch: mm.notch } }
}
