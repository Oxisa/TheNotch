import QtQuick
import qs.Commons
import "../../../fonts"

Column {
  id: root

  property var parts
  property bool use24h: true
  property real uiScale: 1
  property string clockFont: Fonts.desk
  property string labelFont: Fonts.desk
  property real dateFontSize: 11
  property real dayFontSize: 18
  property real ampmFontSize: 10
  property color primaryColor: Color.foreground
  property color mutedColor: Color.muted

  spacing: Math.round(4 * root.uiScale)
  anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined

  Text {
    text: root.parts.dateShort
    color: root.mutedColor
    font.family: root.labelFont
    font.pixelSize: Math.round(root.dateFontSize * root.uiScale)
    font.weight: Font.Medium
    font.letterSpacing: 2.2
    horizontalAlignment: Text.AlignHCenter
    renderType: Text.NativeRendering
    antialiasing: true
  }

  Text {
    text: root.parts.dayName
    color: root.primaryColor
    font.family: root.clockFont
    font.pixelSize: Math.round(root.dayFontSize * root.uiScale)
    font.weight: Font.Bold
    font.letterSpacing: 1.2
    horizontalAlignment: Text.AlignHCenter
    renderType: Text.NativeRendering
    antialiasing: true
  }

  Text {
    visible: !root.use24h
    text: root.parts.ampm
    color: root.mutedColor
    font.family: root.labelFont
    font.pixelSize: Math.round(root.ampmFontSize * root.uiScale)
    font.weight: Font.DemiBold
    font.letterSpacing: 3
    horizontalAlignment: Text.AlignHCenter
    renderType: Text.NativeRendering
    antialiasing: true
  }
}
