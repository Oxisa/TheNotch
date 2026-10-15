import QtQuick
import Quickshell
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// NanoKVM's page: what is running and the buttons.
Column {
  id: page
  property var mod: null
  spacing: SH.HubStyle.gap
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }
  readonly property var st: mod ? mod.st : ({})

  component StatusLine: Row {
    property string label: ""
    property bool on: false
    spacing: Style.space(8)
    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(8); height: width; radius: width / 2
      color: parent.on ? page.accent : SH.HubStyle.tint(page.fg, 0.25)
    }
    Text { text: parent.label; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.body }
  }

  SH.HubCard {
    width: page.width
    height: col.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    Column {
      id: col
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      spacing: Style.space(12)
      Text { text: page.t("Состояние", "Status"); color: Qt.darker(page.fg, 1.4); font.family: page.ff; font.pixelSize: Style.font.caption; font.bold: true }
      StatusLine { label: page.st.server ? page.t("Сервер запущен · localhost:8080", "Server running · localhost:8080") : page.t("Сервер остановлен", "Server stopped"); on: !!page.st.server }
      StatusLine { label: page.st.window ? page.t("Окно открыто", "Window open") : page.t("Окно закрыто", "Window closed"); on: !!page.st.window }
      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(8)
        SH.HubChip {
          icon: "\u{f0379}"
          label: page.st.window ? page.t("Показать окно", "Show window") : page.t("Открыть экран", "Open screen")
          on: true
          h: Style.space(36)
          fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
          onClicked: page.mod.run("open")
        }
        SH.HubChip {
          visible: !!page.st.window || !!page.st.server
          icon: "\u{f0156}"; label: page.t("Закрыть", "Close")
          h: Style.space(36)
          fg: page.fg; accent: page.accent; fontFamily: page.ff
          onClicked: page.mod.run("stop")
        }
      }
    }
  }
  Text {
    width: page.width
    wrapMode: Text.WordWrap
    text: page.t("Закрытие окна останавливает сервер. В первый раз страница попросит доступ к порту и камере — это сам NanoKVM.",
                 "Closing the window stops the server. The first time, the page asks for the serial port and the camera: that is NanoKVM itself.")
    color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption - 1
  }
}
