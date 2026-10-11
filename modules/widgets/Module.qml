import QtQuick
import "../.."

// Settings → Widgets: every desktop widget in one place. A widget belongs
// to a module; with the module off its card is greyed out and offers to
// switch the module on.
NotchModule {
  id: wm
  title: notch && notch.lang === "ru" ? "Виджеты" : "Widgets"
  icon: "\u{f072c}"
  inRail: false
  core: true
  sectionOrder: 2
  settingsPage: Component { WidgetsPage { notch: wm.notch } }
}
