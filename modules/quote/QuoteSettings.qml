import QtQuick
import qs.Commons
import "../../../osia.soundhub" as SH

// Quotes' section in the settings window: how often the quote changes and
// the translation language (the desktop quote is under Settings → Widgets).
Column {
  id: page
  property var mod: null
  spacing: SH.HubStyle.gap

  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Style.font.family

  SH.HubCard {
    width: parent.width
    height: setCol.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    Column {
      id: setCol
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      spacing: Style.space(10)
      SH.HubRow {
        title: page.mod ? page.mod.t("change") : ""; fg: page.fg; fontFamily: page.ff
        SH.HubSelect {
          width: Style.space(170); showLabel: false
          options: [15, 30, 60, 120, 240, 480, 1440].map(function(m) { return { value: String(m), label: page.mod ? page.mod.every(m) : String(m) } })
          value: page.mod ? String(page.mod.cfg.intervalMinutes) : "240"
          foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
          onChanged: function(v) { page.mod.set("intervalMinutes", parseInt(v, 10)) }
        }
      }
      SH.HubRow {
        title: page.mod ? page.mod.t("lang") : ""; fg: page.fg; fontFamily: page.ff
        SH.HubSelect {
          width: Style.space(170); showLabel: false
          options: [{ value: "ru", label: "Русский" }, { value: "en", label: "English" }]
          value: page.mod ? page.mod.cfg.lang : "ru"
          foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
          onChanged: function(v) { page.mod.set("lang", v) }
        }
      }
    }
  }
}
