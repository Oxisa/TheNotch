import QtQuick
import qs.Commons
import "../../../osia.soundhub" as SH
import "../settings"

// Settings → System → Notifications: do not disturb and which events pop
// out of the notch.
Column {
  id: page
  property var mod: null
  spacing: SH.HubStyle.gap
  SH.HubCard {
    width: page.width
    height: dndRow.implicitHeight + SH.HubStyle.pad * 2
    fg: Color.foreground; accent: Color.accent
    SH.HubRow {
      id: dndRow
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      icon: "\u{f009b}"
      title: page.mod ? page.mod.t("dnd") : ""; hint: page.mod ? page.mod.t("dndHint") : ""
      fg: Color.foreground; fontFamily: Style.font.family
      SH.HubSwitch {
        checked: page.mod ? page.mod.dnd : false
        fg: Color.foreground; accent: Color.accent; ink: Color.background
        onToggled: page.mod.setDnd(!checked)
      }
    }
  }
  SettingsPage { width: page.width; notch: page.mod ? page.mod.notch : null; part: "events" }
}
