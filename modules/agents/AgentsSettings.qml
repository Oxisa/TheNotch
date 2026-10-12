import QtQuick
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// Agents' section in the settings window: when a limit shows in the notch.
Column {
  id: page
  property var mod: null
  spacing: SH.HubStyle.gap
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }

  SH.HubCard {
    width: parent.width
    height: c1.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    Column {
      id: c1
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      spacing: Style.space(10)
      SH.HubRow {
        title: page.t("Показывать в чёлке от", "Show in the notch from")
        hint: page.t("Лимит выше этого ненадолго выезжает в чёлке", "A limit above this pops out in the notch for a moment")
        fg: page.fg; fontFamily: page.ff
        SH.HubSelect {
          width: Style.space(170); showLabel: false
          options: [0.5, 0.7, 0.8, 0.9].map(function(v) { return { value: String(v), label: Math.round(v * 100) + "%" } })
          value: page.mod ? String(page.mod.threshold) : "0.8"
          foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
          onChanged: function(v) { page.mod.persist({ threshold: Number(v) }) }
        }
      }
      SH.HubRow {
        title: page.t("Затем каждые", "Then every")
        hint: page.t("Снова показать, когда лимит вырос ещё на столько", "Show again when the limit has grown by this much")
        fg: page.fg; fontFamily: page.ff
        SH.HubSelect {
          width: Style.space(170); showLabel: false
          options: [0.01, 0.02, 0.05, 0.1].map(function(v) { return { value: String(v), label: Math.round(v * 100) + "%" } })
          value: page.mod ? String(page.mod.step) : "0.05"
          foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
          onChanged: function(v) { page.mod.persist({ step: Number(v) }) }
        }
      }
      SH.HubRow {
        title: page.t("Держать в чёлке постоянно", "Keep it in the notch")
        hint: page.t("Пока лимит выше порога — вместо часов", "While above the threshold — instead of the clock")
        fg: page.fg; fontFamily: page.ff
        SH.HubSwitch { checked: !!(page.mod && page.mod.always); fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.mod.persist({ always: !page.mod.always }) }
      }
    }
  }
}
