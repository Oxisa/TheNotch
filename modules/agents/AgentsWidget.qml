import QtQuick
import qs.Commons
import "../../../osia.soundhub" as SH

// Agent limits as a desktop widget: just the rings — one nested ring per
// agent (outer: session, inner: week) with its name — on a small card.
// TheNotch's widget layer places it.
Rectangle {
  id: card
  property var mod: null
  property bool editing: false
  readonly property bool deskShown: true
  property bool deskVertical: false                // turned 90°: the rings stack in a column
  // the agents ticked in the widget's settings (Claude, Codex or both)
  readonly property var picked: mod ? mod.opt("widgetAgents", ["claude", "codex"]) : ["claude", "codex"]
  readonly property var shownAgents: (mod ? mod.agents : []).filter(function(a) { return picked.indexOf(a.id) >= 0 })
  width: rings.implicitWidth + Style.space(32)
  height: rings.implicitHeight + Style.space(28)
  radius: SH.HubStyle.radius + Style.space(4)
  readonly property color bg: Color.background
  color: Qt.rgba(bg.r, bg.g, bg.b, mod ? Number(mod.opt("widgetOpacity", 0.85)) : 0.85)
  border.width: 1
  border.color: SH.HubStyle.tint(Color.foreground, 0.08)
  Grid {
    id: rings
    anchors.centerIn: parent
    columns: card.deskVertical ? 1 : 99
    spacing: Style.space(22)
    Repeater {
      model: card.shownAgents
      delegate: RingPair {
        required property var modelData
        agentData: modelData
        ru: card.mod ? card.mod.ru : true
        size: Style.space(60)
      }
    }
  }
}
