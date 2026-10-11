import QtQuick
import qs.Commons
import "../../../osia.soundhub" as SH
import "../../DeskStyle.js" as DS

// The minimal network widget: a ring of signal (Wi-Fi) or a full ring
// (cable), the glyph in the middle, the download speed under it.
Item {
  id: r
  property var mod: null
  property bool editing: false
  readonly property bool deskShown: true
  property var deskStyle: ({})
  property real deskScale: 1
  readonly property color fg: DS.fg(deskStyle, Color.foreground)
  readonly property color accent: DS.accent(deskStyle, Color.accent)
  readonly property string ff: Style.font.family
  readonly property color bgc: Color.background
  readonly property real level: !mod || !mod.online ? 0 : mod.onWifi ? (mod.primary.signal || 0) / 100 : 1
  width: Style.space(120) * deskScale; height: Style.space(140) * deskScale
  onLevelChanged: ring.requestPaint()
  Rectangle {
    width: Style.space(110) * r.deskScale; height: width; radius: width / 2
    anchors.horizontalCenter: parent.horizontalCenter
    color: DS.bg(r.deskStyle, r.bgc, r.accent, r.mod ? Number(r.mod.opt("opacity", 0.85)) : 0.85)
    Canvas {
      id: ring
      anchors.fill: parent
      onPaint: {
        var ctx = getContext("2d"); ctx.reset()
        var c = width / 2, rad = c - Style.space(8)
        ctx.lineWidth = Style.space(7); ctx.lineCap = "round"
        ctx.strokeStyle = Qt.rgba(r.fg.r, r.fg.g, r.fg.b, 0.12)
        ctx.beginPath(); ctx.arc(c, c, rad, 0, Math.PI * 2); ctx.stroke()
        if (r.level > 0) {
          ctx.strokeStyle = r.accent
          ctx.beginPath(); ctx.arc(c, c, rad, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * r.level); ctx.stroke()
        }
      }
      Component.onCompleted: requestPaint()
    }
    Text { anchors.centerIn: parent; text: r.mod ? r.mod.glyph : ""; color: r.mod && r.mod.online ? r.accent : r.fg; font.family: r.ff; font.pixelSize: Style.space(34) * r.deskScale }
  }
  Text {
    anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
    text: r.mod ? "\u{f0045} " + r.mod.rate(r.mod.down) : ""
    color: r.fg
    font.family: r.ff; font.pixelSize: Style.font.caption; font.bold: true
    style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.5)
  }
}
