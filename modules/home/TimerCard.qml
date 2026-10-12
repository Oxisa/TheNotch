import QtQuick
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// Timer / stopwatch / pomodoro: the switch on top, the big number, presets,
// start-pause and reset. A running one also shows in the collapsed notch.
Column {
  id: tc
  property var mod: null
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property string ff: Fonts.ui
  readonly property bool isTimer: mod ? mod.clockMode === "timer" : true
  readonly property bool isPomo: mod ? mod.clockMode === "pomodoro" : false
  readonly property bool running: mod ? (isPomo ? mod.pomoRunning : isTimer ? mod.timerRunning : mod.swRunning) : false
  spacing: Style.space(6)

  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Style.space(4)
    Repeater {
      model: [{ id: "timer", label: tc.mod ? tc.mod.t("Таймер", "Timer") : "" }, { id: "stopwatch", label: tc.mod ? tc.mod.t("Секундомер", "Stopwatch") : "" },
              { id: "pomodoro", label: tc.mod ? tc.mod.t("Помодоро", "Pomodoro") : "" }].filter(function(m) { return m.id !== "pomodoro" || (tc.mod && tc.mod.pomo !== undefined) })
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
  // pomodoro: the phase and the rounds
  Row {
    visible: tc.isPomo
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Style.space(8)
    Text { anchors.verticalCenter: parent.verticalCenter; text: tc.mod && tc.isPomo ? tc.mod.phaseName(tc.mod.phase) : ""; color: tc.accent; font.family: tc.ff; font.pixelSize: Style.font.caption + 1; font.bold: true }
    Repeater {
      model: tc.mod && tc.isPomo ? tc.mod.pomo.cycles : 0
      delegate: Rectangle {
        required property int index
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(8); height: width; radius: width / 2
        color: index < (tc.mod.done % tc.mod.pomo.cycles) ? tc.accent : SH.HubStyle.tint(tc.fg, 0.2)
      }
    }
  }
  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    text: tc.mod ? tc.mod.fmt(tc.isPomo ? (tc.mod.phase === "idle" ? tc.mod.pomo.work * 60000 : tc.mod.pomoRemaining) : tc.isTimer ? tc.mod.remaining : tc.mod.elapsed) : "0:00"
    color: tc.running ? tc.accent : tc.fg
    font.family: tc.ff; font.pixelSize: Style.space(32); font.bold: true
  }
  // pomodoro presets (work / break) and two switches
  Row {
    visible: tc.isPomo
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Style.space(4)
    Repeater {
      model: [[25, 5, 15], [50, 10, 20], [90, 20, 30]]
      delegate: Rectangle {
        required property var modelData
        readonly property bool on: tc.mod && tc.mod.pomo.work === modelData[0] && tc.mod.pomo.short === modelData[1]
        width: pl.implicitWidth + Style.space(14); height: Style.space(22); radius: height / 2
        color: on ? SH.HubStyle.tint(tc.accent, 0.35) : SH.HubStyle.tint(tc.fg, pm2.containsMouse ? 0.14 : 0.06)
        Text { id: pl; anchors.centerIn: parent; text: modelData[0] + "/" + modelData[1]; color: tc.fg; font.family: tc.ff; font.pixelSize: Style.font.caption - 1 }
        MouseArea { id: pm2; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tc.mod.setPomo({ work: modelData[0], short: modelData[1], long: modelData[2] }) }
      }
    }
  }
  Row {
    visible: tc.isPomo
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Style.space(4)
    SH.HubChip {
      icon: "\u{f0379}"; label: tc.mod ? tc.mod.t("Затемнять на перерыв", "Dim on breaks") : ""
      on: tc.mod && tc.mod.pomo.overlay; subtle: true; h: Style.space(22)
      fg: tc.fg; accent: tc.accent; fontFamily: tc.ff
      onClicked: tc.mod.setPomo({ overlay: !tc.mod.pomo.overlay })
    }
    SH.HubChip {
      icon: "󱅻"; label: tc.mod ? tc.mod.t("Звуки фокуса", "Focus sounds") : ""
      on: tc.mod && tc.mod.pomo.sounds; subtle: true; h: Style.space(22)
      fg: tc.fg; accent: tc.accent; fontFamily: tc.ff
      onClicked: tc.mod.setPomo({ sounds: !tc.mod.pomo.sounds })
    }
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
      onClicked: tc.isPomo ? tc.mod.pomoStartPause() : tc.mod.startPause()
    }
    SH.HubChip {
      iconOnly: true
      icon: "\u{f099b}"
      label: tc.mod ? tc.mod.t("Сброс", "Reset") : ""
      h: Style.space(26)
      fg: tc.fg; accent: tc.accent; fontFamily: tc.ff
      onClicked: tc.isPomo ? tc.mod.pomoReset() : tc.mod.reset()
    }
  }
}
