import QtQuick
import "../.."

// Settings → Credits & licenses: whose code, sounds, fonts and services
// TheNotch and its parts use, with authors, licenses and links.
NotchModule {
  id: cr
  title: notch && notch.lang === "ru" ? "Авторы и лицензии" : "Credits & licenses"
  icon: "\u{f05d1}"
  inRail: false
  core: true
  sectionOrder: 95
  settingsSection: "about"
  settingsPage: Component { CreditsPage { ru: cr.notch !== null && cr.notch.lang === "ru" } }
}
