import QtQuick
import "../.."

// Settings → Omarchy plugins: the plugin manager, inside the notch.
NotchModule {
  id: pm
  title: notch && notch.lang === "ru" ? "Плагины Omarchy" : "Omarchy plugins"
  icon: "\u{f06a5}"
  inRail: false
  core: true
  sectionOrder: 90
  settingsSection: "plugins"
  settingsPage: Component { PluginsPage { notch: pm.notch } }
}
