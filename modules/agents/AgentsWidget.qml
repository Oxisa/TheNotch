import QtQuick
import qs.Commons
import "../../../osia.soundhub" as SH
import "../../DeskStyle.js" as DS

// Agent limits as a desktop widget: just the rings — one nested ring per
// agent (outer: session, inner: week) with its name — on a small card.
// TheNotch's widget layer places it.
Rectangle {
  id: card
  property var mod: null
  property bool editing: false
  readonly property bool deskShown: true
  property bool deskVertical: false
  property var deskStyle: ({})
  property real deskScale: 1                // turned 90°: the rings stack in a column
  // the agents ticked in the widget's settings (Claude, Codex or both)
  readonly property var picked: mod ? mod.opt("widgetAgents", ["claude", "codex"]) : ["claude", "codex"]
  readonly property var shownAgents: (mod ? mod.agents : []).filter(function(a) { return picked.indexOf(a.id) >= 0 })
  width: rings.implicitWidth + Style.space(32) * deskScale
  height: rings.implicitHeight + Style.space(28) * deskScale
  radius: DS.radius(deskStyle, SH.HubStyle.radius + Style.space(4))
  topLeftRadius: DS.corner(deskStyle, "tl", SH.HubStyle.radius + Style.space(4))
  topRightRadius: DS.corner(deskStyle, "tr", SH.HubStyle.radius + Style.space(4))
  bottomLeftRadius: DS.corner(deskStyle, "bl", SH.HubStyle.radius + Style.space(4))
  bottomRightRadius: DS.corner(deskStyle, "br", SH.HubStyle.radius + Style.space(4))
  readonly property color bg: Color.background
  color: DS.bg(deskStyle, bg, Color.accent, mod ? Number(mod.opt("widgetOpacity", 0.85)) : 0.85)
  border.width: 1
  border.color: DS.border(deskStyle, Color.foreground)
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
        showLogo: card.mod ? card.mod.opt("logo", true) !== false : true
        showName: card.mod ? card.mod.opt("label", true) !== false : true
        size: Style.space(60) * card.deskScale
      }
    }
  }
}
