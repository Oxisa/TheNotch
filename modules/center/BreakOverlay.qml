import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// The pomodoro break: a dimmed screen with the time left and a way out —
// it asks you to step away, it doesn't trap you.
PanelWindow {
  id: ov
  property var mod: null
  color: "transparent"
  anchors { top: true; bottom: true; left: true; right: true }
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "osia-thenotch-break"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent

  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.78)
    opacity: 0
    Component.onCompleted: opacity = 1
    Behavior on opacity { NumberAnimation { duration: 600 } }
    MouseArea { anchors.fill: parent }
    Column {
      anchors.centerIn: parent
      spacing: Style.space(16)
      Text { anchors.horizontalCenter: parent.horizontalCenter; text: "\u{f0176}"; color: ov.accent; font.family: Fonts.ui; font.pixelSize: Style.space(64) }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: ov.mod ? ov.mod.phaseName(ov.mod.phase) : ""
        color: "white"; font.family: Fonts.ui; font.pixelSize: Style.space(30); font.bold: true
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: ov.mod ? ov.mod.fmt(ov.mod.pomoRemaining) : ""
        color: ov.accent; font.family: Fonts.ui; font.pixelSize: Style.space(96); font.bold: true
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: ov.mod ? ov.mod.t("Встаньте, разомнитесь, посмотрите вдаль", "Stand up, stretch, look far away") : ""
        color: Qt.rgba(1, 1, 1, 0.7); font.family: Fonts.ui; font.pixelSize: Style.font.body + 2
      }
      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(10)
        SH.HubChip {
          icon: "\u{f04ad}"; label: ov.mod ? ov.mod.t("Пропустить перерыв", "Skip the break") : ""
          h: Style.space(34)
          fg: "white"; accent: ov.accent; fontFamily: Fonts.ui
          onClicked: ov.mod.skipBreak()
        }
        SH.HubChip {
          icon: "\u{f04db}"; label: ov.mod ? ov.mod.t("Остановить помодоро", "Stop the pomodoro") : ""
          h: Style.space(34)
          fg: "white"; accent: ov.accent; fontFamily: Fonts.ui
          onClicked: ov.mod.pomoReset()
        }
      }
    }
  }
}
