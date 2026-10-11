import QtQuick
import qs.Commons
import "../../../osia.soundhub" as SH

// Timer / stopwatch: the switch on top, the big number, presets for the
// timer, start-pause and reset. A running one also shows in the collapsed notch.
Column {
  id: tc
  property var mod: null
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property string ff: Style.font.family
  readonly property bool isTimer: mod ? mod.clockMode === "timer" : true
  readonly property bool running: mod ? (isTimer ? mod.timerRunning : mod.swRunning) : false
  spacing: Style.space(6)

  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Style.space(4)
    Repeater {
      model: [{ id: "timer", label: tc.mod ? tc.mod.t("Таймер", "Timer") : "" }, { id: "stopwatch", label: tc.mod ? tc.mod.t("Секундомер", "Stopwatch") : "" }]
      delegate: SH.HubChip {
        required property var modelData
        label: modelData.label
        on: tc.mod && tc.mod.clockMode === modelData.id
        subtle: true
        h: Style.space(24)
        fg: tc.fg; accent: tc.accent; fontFamily: tc.ff
        onClicked: tc.mod.clockMode = modelData.id
      }
    }
  }
  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    text: tc.mod ? tc.mod.fmt(tc.isTimer ? tc.mod.remaining : tc.mod.elapsed) : "0:00"
    color: tc.running ? tc.accent : tc.fg
    font.family: tc.ff; font.pixelSize: Style.space(32); font.bold: true
  }
  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Style.space(4)
    visible: tc.isTimer
    Repeater {
      model: [1, 5, 10, 25, 60]
      delegate: Rectangle {
        required property int modelData
        width: Style.space(30); height: Style.space(22); radius: height / 2
        color: SH.HubStyle.tint(tc.fg, pm.containsMouse ? 0.14 : 0.06)
        Text { anchors.centerIn: parent; text: modelData; color: tc.fg; font.family: tc.ff; font.pixelSize: Style.font.caption - 1 }
        MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tc.mod.setTimer(modelData) }
      }
    }
  }
  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Style.space(8)
    SH.HubChip {
      icon: tc.running ? "\u{f03e4}" : "\u{f040a}"
      label: tc.mod ? (tc.running ? tc.mod.t("Пауза", "Pause") : tc.mod.t("Старт", "Start")) : ""
      on: true
      h: Style.space(26)
      fg: tc.fg; accent: tc.accent; ink: Color.background; fontFamily: tc.ff
      onClicked: tc.mod.startPause()
    }
    SH.HubChip {
      iconOnly: true
      icon: "\u{f099b}"
      label: tc.mod ? tc.mod.t("Сброс", "Reset") : ""
      h: Style.space(26)
      fg: tc.fg; accent: tc.accent; fontFamily: tc.ff
      onClicked: tc.mod.reset()
    }
  }
}
