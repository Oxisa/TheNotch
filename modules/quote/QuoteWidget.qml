import QtQuick
import qs.Commons
import "../../../osia.soundhub" as SH

// The desktop quote's card in Settings → Widgets: show, position, size,
// background, move by hand, reset.
Column {
  id: page
  property var mod: null
  spacing: Style.space(10)

  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Style.font.family

      SH.HubRow {
        title: page.mod ? page.mod.t("show") : ""; fg: page.fg; fontFamily: page.ff
        SH.HubSwitch {
          checked: page.mod ? page.mod.cfg.visible : false
          fg: page.fg; accent: page.accent; ink: page.bgc
          onToggled: page.mod.set("visible", !checked)
        }
      }
      SH.HubRow {
        title: page.mod ? page.mod.t("place") : ""; fg: page.fg; fontFamily: page.ff
        SH.HubPlacePicker {
          value: page.mod ? page.mod.place : ""
          fg: page.fg; accent: page.accent
          onPicked: function(p) { page.mod.setPlace(p) }
        }
      }
      SH.HubRow {
        title: page.mod ? page.mod.t("size") : ""; fg: page.fg; fontFamily: page.ff
        SH.HubSlider {
          width: Style.space(170)
          minimum: 0.6; maximum: 2.0; step: 0.05
          value: page.mod ? page.mod.cfg.scale : 1
          fillColor: page.accent; fontFamily: page.ff
          onReleased: function(v) { page.mod.set("scale", v) }
        }
      }
      SH.HubRow {
        title: page.mod ? page.mod.t("background") : ""; fg: page.fg; fontFamily: page.ff
        SH.HubSlider {
          width: Style.space(170)
          minimum: 0; maximum: 0.85; step: 0.05
          value: page.mod ? page.mod.cfg.backgroundOpacity : 0.4
          fillColor: page.accent; fontFamily: page.ff
          onReleased: function(v) { page.mod.set("backgroundOpacity", v) }
        }
      }
      Row {
        spacing: Style.space(6)
        SH.HubChip {
          icon: "\u{f01be}"; label: page.mod ? page.mod.t("move") : ""
          fg: page.fg; accent: page.accent; fontFamily: page.ff
          onClicked: page.mod.move()
        }
        SH.HubChip {
          icon: "󰑓"; label: page.mod ? page.mod.t("reset") : ""
          fg: page.fg; accent: page.accent; fontFamily: page.ff
          onClicked: page.mod.resetLook()
        }
      }
}
