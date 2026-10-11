import QtQuick
import qs.Commons
import "../osia.soundhub" as SH

// Tabs inside a settings page: a row of underlined labels. `tabs` is a list
// of { id, label, icon }; `current` is the open one.
Row {
  id: st
  property var tabs: []
  property string current: tabs.length ? tabs[0].id : ""
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property string ff: Style.font.family
  spacing: Style.space(18)
  height: Style.space(34)
  Repeater {
    model: st.tabs
    delegate: Item {
      id: t
      required property var modelData
      readonly property bool on: st.current === modelData.id
      width: lab.implicitWidth; height: st.height
      Row {
        id: lab
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(6)
        Text { visible: !!t.modelData.icon; text: t.modelData.icon || ""; color: t.on ? st.accent : Qt.darker(st.fg, 1.5); font.family: st.ff; font.pixelSize: Style.font.body }
        Text { text: t.modelData.label; color: t.on ? st.fg : Qt.darker(st.fg, tm.containsMouse ? 1.1 : 1.5); font.family: st.ff; font.pixelSize: Style.font.body; font.bold: t.on }
      }
      Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 2; radius: 1; color: st.accent; visible: t.on }
      MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: st.current = t.modelData.id }
    }
  }
}
