import QtQuick
import "../.."

// TheNotch's own settings as a dashboard: edge, the Omarchy bar, closing,
// colour, language and which live events to show.
NotchModule {
  id: mod
  title: notch ? notch.t("settings") : "TheNotch"
  icon: "󰒓"
  pageWidth: 440
  page: Component { SettingsPage { notch: mod.notch } }
}
