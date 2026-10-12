import QtQuick
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../DeskStyle.js" as DS
import "../../fonts"

// "Batteries" like the macOS widget: a ring per device with its glyph in the
// middle and the charge under it (rings), or a row each with a bar (list).
// Turned 90°, the rings stack in a column.
Rectangle {
  id: w
  property var mod: null
  property bool editing: false
  property bool deskVertical: false
  property real deskScale: 1
  readonly property var items: mod ? (mod.st.batteries || []) : []
  readonly property bool deskShown: items.length > 0 || editing
  readonly property string look: mod ? String(mod.opt("look", "rings")) : "rings"
  readonly property bool names: mod ? mod.opt("names", true) !== false : true
  property var deskStyle: ({})
  readonly property color fg: DS.fg(deskStyle, Color.foreground)
  readonly property color accent: DS.accent(deskStyle, Color.accent)
  readonly property string ff: Fonts.desk
  readonly property color bgc: Color.background
  width: (look === "list" ? listCol.width : ringGrid.implicitWidth) + Style.space(32)
  height: (look === "list" ? listCol.implicitHeight : ringGrid.implicitHeight) + Style.space(28)
  radius: DS.radius(deskStyle, Style.space(22))
  topLeftRadius: DS.corner(deskStyle, "tl", Style.space(22))
  topRightRadius: DS.corner(deskStyle, "tr", Style.space(22))
  bottomLeftRadius: DS.corner(deskStyle, "bl", Style.space(22))
  bottomRightRadius: DS.corner(deskStyle, "br", Style.space(22))
  color: DS.bg(deskStyle, bgc, accent, mod ? Number(mod.opt("opacity", 0.85)) : 0.85)
  border.width: 1
  border.color: DS.border(deskStyle, Color.foreground)
  function tone(p) { return p <= 15 ? Color.urgent : p <= 30 ? "#e5b450" : w.accent }

  Grid {
    id: ringGrid
    visible: w.look === "rings"
    anchors.centerIn: parent
    columns: w.deskVertical ? 1 : Math.max(1, Math.min(4, w.items.length))
    spacing: Style.space(16)
    Repeater {
      model: w.items.length ? w.items : (w.editing ? [{ name: w.mod ? w.mod.t("Устройства", "Devices") : "", kind: "", percent: 0 }] : [])
      delegate: Column {
        required property var modelData
        spacing: Style.space(6)
        Item {
          anchors.horizontalCenter: parent.horizontalCenter
          width: Style.space(62) * w.deskScale; height: width
          Canvas {
            anchors.fill: parent
            property real p: modelData.percent
            onPChanged: requestPaint()
            onPaint: {
              var ctx = getContext("2d"); ctx.reset()
              var c = width / 2, r = c - Style.space(4)
              ctx.lineWidth = Style.space(5); ctx.lineCap = "round"
              ctx.strokeStyle = Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.12)
              ctx.beginPath(); ctx.arc(c, c, r, 0, Math.PI * 2); ctx.stroke()
              if (p > 0) { ctx.strokeStyle = w.tone(p); ctx.beginPath(); ctx.arc(c, c, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * p / 100); ctx.stroke() }
            }
            Component.onCompleted: requestPaint()
          }
          Text { anchors.centerIn: parent; text: w.mod ? w.mod.glyph(modelData.kind) : ""; color: w.fg; font.family: w.ff; font.pixelSize: Style.space(24) * w.deskScale }
          Text {
            visible: !!modelData.charging
            anchors.right: parent.right; anchors.top: parent.top
            text: "\u{f140b}"; color: w.accent; font.family: w.ff; font.pixelSize: Style.font.caption
          }
        }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.percent + "%"; color: w.fg; font.family: w.ff; font.pixelSize: Style.font.body; font.bold: true }
        Text {
          visible: w.names
          anchors.horizontalCenter: parent.horizontalCenter
          width: Style.space(80); horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
          text: modelData.name
          color: Qt.darker(w.fg, 1.45); font.family: w.ff; font.pixelSize: Style.font.caption - 2
        }
      }
    }
  }

  Column {
    id: listCol
    visible: w.look === "list"
    anchors.centerIn: parent
    width: Style.space(260)
    spacing: Style.space(10)
    Repeater {
      model: w.items
      delegate: Item {
        required property var modelData
        width: listCol.width; height: Style.space(26)
        Row {
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(10)
          Text { anchors.verticalCenter: parent.verticalCenter; text: w.mod.glyph(modelData.kind); color: w.accent; font.family: w.ff; font.pixelSize: Style.font.body + 2 }
          Text { anchors.verticalCenter: parent.verticalCenter; visible: w.names; width: Style.space(110); elide: Text.ElideRight; text: modelData.name; color: w.fg; font.family: w.ff; font.pixelSize: Style.font.caption + 1 }
        }
        Row {
          anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(8)
          Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(60); height: Style.space(6); radius: height / 2
            color: SH.HubStyle.tint(w.fg, 0.12)
            Rectangle { width: parent.width * modelData.percent / 100; height: parent.height; radius: height / 2; color: w.tone(modelData.percent) }
          }
          Text { width: Style.space(36); horizontalAlignment: Text.AlignRight; text: modelData.percent + "%"; color: w.fg; font.family: w.ff; font.pixelSize: Style.font.caption; font.bold: true }
        }
      }
    }
  }
}
