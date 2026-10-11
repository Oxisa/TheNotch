import QtQuick
import qs.Commons
import "../../../osia.soundhub" as SH

// "Agent limits" card in Settings → Widgets.
Column {
  id: page
  property var mod: null
  spacing: Style.space(10)
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Style.font.family
  function t(a, b) { return mod ? mod.t(a, b) : b }

  SH.HubRow {
    title: page.t("Показывать на рабочем столе", "Show on the desktop")
    hint: page.t("Кольца Claude и Codex под окнами", "Claude and Codex rings under the windows")
    fg: page.fg; fontFamily: page.ff
    SH.HubSwitch {
      checked: page.mod ? page.mod.opt("widget", false) === true : false
      fg: page.fg; accent: page.accent; ink: page.bgc
      onToggled: page.mod.persist({ widget: !checked })
    }
  }
  // which agents the widget shows: one, the other or both
  Flow {
    width: parent.width
    spacing: Style.space(6)
    Repeater {
      model: [{ id: "claude", label: "Claude" }, { id: "codex", label: "Codex" }]
      delegate: SH.HubChip {
        required property var modelData
        readonly property var picked: page.mod ? page.mod.opt("widgetAgents", ["claude", "codex"]) : ["claude", "codex"]
        readonly property bool on_: picked.indexOf(modelData.id) >= 0
        icon: on_ ? "󰄬" : "󰅖"
        label: modelData.label
        on: on_
        subtle: true
        h: Style.space(26)
        fg: page.fg; accent: page.accent; fontFamily: page.ff
        onClicked: {
          var p = picked.slice()
          if (on_) { if (p.length === 1) return; p = p.filter(function(x) { return x !== modelData.id }) }
          else p.push(modelData.id)
          page.mod.persist({ widgetAgents: p })
        }
      }
    }
  }
  SH.HubRow {
    title: page.t("Фон", "Background"); fg: page.fg; fontFamily: page.ff
    SH.HubSlider {
      width: Style.space(176)
      minimum: 0.2; maximum: 1; step: 0.05
      value: page.mod ? Number(page.mod.opt("widgetOpacity", 0.85)) : 0.85
      fillColor: page.accent; fontFamily: page.ff
      onReleased: function(v) { page.mod.persist({ widgetOpacity: Math.round(v * 100) / 100 }) }
    }
  }
}
