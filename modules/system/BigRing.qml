import QtQuick
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// A large ring: the main value as an arc and big text in the middle, a
// second value as a short arc along the lower right.
Item {
  id: br
  property real value: 0                       // 0..1, the main arc
  property real value2: -1                     // 0..1, the small arc; < 0 hides it
  property string big: ""
  property string label: ""
  property string small: ""                    // under the small arc
  property real size: Style.space(170)
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  width: size; height: size
  onValueChanged: arc.requestPaint()
  onValue2Changed: arc.requestPaint()
  Canvas {
    id: arc
    anchors.fill: parent
    onPaint: {
      var ctx = getContext("2d"); ctx.reset()
      var c = width / 2, r = c - Style.space(10), lw = Style.space(9)
      var a0 = Math.PI * 0.75, span = Math.PI * 1.5
      ctx.lineCap = "round"; ctx.lineWidth = lw
      ctx.strokeStyle = SH.HubStyle.tint(br.fg, 0.10)
      ctx.beginPath(); ctx.arc(c, c, r, a0, a0 + span); ctx.stroke()
      ctx.strokeStyle = br.accent
      ctx.beginPath(); ctx.arc(c, c, r, a0, a0 + span * Math.max(0.005, Math.min(1, br.value))); ctx.stroke()
      if (br.value2 >= 0) {
        var r2 = r - Style.space(16)
        ctx.lineWidth = Style.space(4)
        ctx.strokeStyle = Qt.rgba(br.fg.r, br.fg.g, br.fg.b, 0.10)
        ctx.beginPath(); ctx.arc(c, c, r2, a0, a0 + span); ctx.stroke()
        ctx.strokeStyle = Qt.rgba(br.fg.r, br.fg.g, br.fg.b, 0.75)
        ctx.beginPath(); ctx.arc(c, c, r2, a0, a0 + span * Math.max(0.005, Math.min(1, br.value2))); ctx.stroke()
      }
    }
  }
  Column {
    anchors.centerIn: parent
    Text { anchors.horizontalCenter: parent.horizontalCenter; text: br.big; color: br.fg; font.family: Fonts.desk; font.pixelSize: br.size * 0.19; font.bold: true }
    Text { anchors.horizontalCenter: parent.horizontalCenter; text: br.label; color: Qt.darker(br.fg, 1.35); font.family: Fonts.desk; font.pixelSize: Style.font.caption }
  }
  Text {
    anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: Style.space(4)
    text: br.small
    color: Qt.darker(br.fg, 1.5)
    font.family: Fonts.desk; font.pixelSize: Style.font.caption - 1
  }
}
