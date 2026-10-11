import QtQuick
import qs.Commons
import "../../../osia.soundhub" as SH
import "../../DeskStyle.js" as DS

// Network card on the desktop: what you're connected through, the speed
// with a minute of history, latency and whether a tunnel is up.
Rectangle {
  id: c
  property var mod: null
  property bool editing: false
  property bool deskVertical: false
  readonly property bool deskShown: true
  property var deskStyle: ({})
  readonly property color fg: DS.fg(deskStyle, Color.foreground)
  readonly property color accent: DS.accent(deskStyle, Color.accent)
  readonly property string ff: Style.font.family
  readonly property color bgc: Color.background
  width: Style.space(c.deskVertical ? 190 : 300)
  height: col.implicitHeight + Style.space(28)
  radius: DS.radius(deskStyle, SH.HubStyle.radius + Style.space(4))
  topLeftRadius: DS.corner(deskStyle, "tl", SH.HubStyle.radius + Style.space(4))
  topRightRadius: DS.corner(deskStyle, "tr", SH.HubStyle.radius + Style.space(4))
  bottomLeftRadius: DS.corner(deskStyle, "bl", SH.HubStyle.radius + Style.space(4))
  bottomRightRadius: DS.corner(deskStyle, "br", SH.HubStyle.radius + Style.space(4))
  color: DS.bg(deskStyle, bgc, accent, mod ? Number(mod.opt("opacity", 0.85)) : 0.85)
  border.width: 1
  border.color: DS.border(deskStyle, Color.foreground)
  Column {
    id: col
    x: Style.space(16); y: Style.space(14)
    width: parent.width - Style.space(32)
    spacing: Style.space(8)
    Row {
      spacing: Style.space(10)
      Text { anchors.verticalCenter: parent.verticalCenter; text: c.mod ? c.mod.glyph : ""; color: c.accent; font.family: c.ff; font.pixelSize: Style.space(24) }
      Column {
        anchors.verticalCenter: parent.verticalCenter
        Text { text: c.mod ? c.mod.name : ""; color: c.fg; font.family: c.ff; font.pixelSize: Style.font.body; font.bold: true; elide: Text.ElideRight; width: col.width - Style.space(40) }
        Text { text: c.mod ? c.mod.sub : ""; color: Qt.darker(c.fg, 1.5); font.family: c.ff; font.pixelSize: Style.font.caption - 1 }
      }
    }
    Grid {
      columns: c.deskVertical ? 1 : 2
      columnSpacing: Style.space(18)
      Text { text: "\u{f0045} " + (c.mod ? c.mod.rate(c.mod.down) : ""); color: c.accent; font.family: c.ff; font.pixelSize: Style.font.caption + 1; font.bold: true }
      Text { text: "\u{f005d} " + (c.mod ? c.mod.rate(c.mod.up) : ""); color: c.fg; font.family: c.ff; font.pixelSize: Style.font.caption + 1 }
    }
    Canvas {
      id: spark
      width: parent.width; height: Style.space(34)
      Connections { target: c.mod; function onHistoryChanged() { spark.requestPaint() } }
      onPaint: {
        var ctx = getContext("2d"); ctx.reset()
        var h = c.mod ? c.mod.history : [], n = h.length
        if (n < 2) return
        var mx = 1
        for (var i = 0; i < n; i++) mx = Math.max(mx, h[i].down, h[i].up)
        ctx.beginPath()
        for (var j = 0; j < n; j++) { var x = j / 59 * width, y = height - h[j].down / mx * (height - 2); if (j === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y) }
        ctx.strokeStyle = c.accent; ctx.lineWidth = 2; ctx.stroke()
        ctx.lineTo((n - 1) / 59 * width, height); ctx.lineTo(0, height); ctx.closePath()
        ctx.fillStyle = Qt.rgba(c.accent.r, c.accent.g, c.accent.b, 0.15); ctx.fill()
      }
    }
    Row {
      spacing: Style.space(12)
      Text {
        visible: !!(c.mod && c.mod.latency.ms)
        text: "\u{f04c5} " + (c.mod && c.mod.latency.ms ? c.mod.latency.ms + c.mod.t(" мс", " ms") : "")
        color: Qt.darker(c.fg, 1.3); font.family: c.ff; font.pixelSize: Style.font.caption - 1
      }
      Text {
        visible: !!(c.mod && c.mod.activeTunnels.length)
        text: "\u{f099d} " + (c.mod ? c.mod.t("туннель", "tunnel") : "")
        color: c.accent; font.family: c.ff; font.pixelSize: Style.font.caption - 1
      }
    }
  }
}
