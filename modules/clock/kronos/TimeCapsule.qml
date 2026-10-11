import QtQuick
import qs.Commons

Rectangle {
  id: root

  property string text: ""
  property real uiScale: 1
  property real textScale: 1
  property string fontFamily: Style.font.family
  property real fontSize: 15
  property int fontWeight: Font.Bold
  property color textColor: Color.foreground
  property color fillColor: Qt.rgba(Color.background.r, Color.background.g, Color.background.b, 0.82)
  property color borderColor: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.14)

  width: Math.round(46 * root.uiScale)
  height: Math.round(34 * root.uiScale)
  radius: height / 2
  color: root.fillColor
  border.color: root.borderColor
  border.width: Math.max(1, root.uiScale)

  Text {
    anchors.centerIn: parent
    text: root.text
    color: root.textColor
    font.family: root.fontFamily
    font.pixelSize: Math.round(root.fontSize * root.textScale)
    font.weight: root.fontWeight
    renderType: Text.NativeRendering
    antialiasing: true
  }
}
