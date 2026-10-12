import QtQuick
import qs.Commons
import qs.Ui
import "../../vendor/soundhub" as SH
import "../../fonts"

// One agent as one nested ring: the outer ring is the short limit (the
// 5-hour session), the inner one the long limit (week, or Codex's window).
// The session percent sits in the middle, the name and the time to its reset
// below. Hover shows every limit with its reset.
Item {
  id: r
  property var agentData: ({})
  property real size: Style.space(72)
  property bool showName: true
  property bool showLogo: true             // the model's logo, faint, behind the percent
  property string sub: ""                  // replaces the reset timer under the name (e.g. "55°C")
  property bool ru: true
  property color fg: Color.foreground
  property color accent: Color.accent
  property color urgent: Color.urgent
  property string fontFamily: Fonts.desk

  readonly property var limits: agentData && agentData.limits ? agentData.limits : []
  readonly property var outer: limits.length > 0 ? limits[0] : null
  readonly property var inner: limits.length > 1 ? limits[1] : null
  function toneOf(p) { return p >= 0.95 ? urgent : p >= 0.8 ? Qt.tint(accent, Qt.rgba(urgent.r, urgent.g, urgent.b, 0.45)) : accent }

  implicitWidth: Math.max(size, nameText.implicitWidth)
  implicitHeight: size + (showName ? col.implicitHeight + Style.space(6) : 0)

  Canvas {
    id: canvas
    width: r.size; height: r.size
    anchors.horizontalCenter: parent.horizontalCenter
    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      var c = width / 2, lw = Math.max(3, width * 0.075)
      function ring(radius, p, color, alpha) {
        ctx.lineCap = "round"; ctx.lineWidth = lw
        ctx.strokeStyle = SH.HubStyle.tint(r.fg, alpha)
        ctx.beginPath(); ctx.arc(c, c, radius, 0, Math.PI * 2); ctx.stroke()
        if (p > 0) {
          ctx.strokeStyle = color
          ctx.beginPath(); ctx.arc(c, c, radius, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.min(1, p)); ctx.stroke()
        }
      }
      var ro = c - lw / 2 - 1
      ring(ro, r.outer ? r.outer.percent : 0, r.outer ? r.toneOf(r.outer.percent) : r.accent, 0.12)
      if (r.inner) {
        var ri = ro - lw * 1.6
        var ic = r.toneOf(r.inner.percent)
        ring(ri, r.inner.percent, Qt.rgba(ic.r, ic.g, ic.b, 0.65), 0.08)
      }
    }
    Connections {
      target: r
      function onAgentDataChanged() { canvas.requestPaint() }
      function onAccentChanged() { canvas.requestPaint() }
    }
    Component.onCompleted: requestPaint()
    Text {
      visible: r.showLogo && !!(r.agentData && r.agentData.glyph)
      anchors.centerIn: parent
      text: r.agentData && r.agentData.glyph ? r.agentData.glyph : ""
      color: r.fg
      opacity: 0.16
      font.family: r.fontFamily; font.pixelSize: Math.round(r.size * 0.5)
    }
    Text {
      anchors.centerIn: parent
      text: r.outer ? Math.round(r.outer.percent * 100) + "%" : "—"
      color: r.outer && r.outer.percent >= 0.95 ? r.urgent : r.fg
      font.family: r.fontFamily; font.pixelSize: Math.round(r.size * 0.2); font.bold: true
    }
    HoverHandler { id: hover }
    PanelToolTip {
      visible: hover.hovered && r.limits.length > 0
      text: r.limits.map(function(l) { return l.label + ": " + Math.round(l.percent * 100) + "%" + (l.reset ? (r.ru ? ", сброс через " : ", resets in ") + l.reset : "") }).join("\n")
    }
  }
  Column {
    id: col
    visible: r.showName
    anchors.top: canvas.bottom; anchors.topMargin: Style.space(6)
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Style.space(1)
    Text {
      id: nameText
      anchors.horizontalCenter: parent.horizontalCenter
      text: r.agentData ? (r.agentData.name || "") : ""
      color: r.fg
      font.family: r.fontFamily; font.pixelSize: Style.font.caption; font.bold: true
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      visible: text !== ""
      text: r.sub !== "" ? r.sub
          : r.agentData && r.agentData.help ? (r.ru ? "нужен вход" : "sign in")
          : !r.outer ? (r.ru ? "нет данных" : "no data")
          : r.outer.reset ? "󰔛 " + r.outer.reset : ""
      color: r.agentData && r.agentData.help ? r.urgent : Qt.darker(r.fg, 1.6)
      font.family: r.fontFamily; font.pixelSize: Style.font.caption - 2
    }
  }
}
