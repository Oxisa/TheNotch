import QtQuick
import Quickshell
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// Settings → Apps → Syncthing.
SH.HubCard {
  id: page
  property var mod: null
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }
  readonly property var st: mod ? mod.st : ({})
  fg: Color.foreground
  width: parent ? parent.width : 400
  height: col.implicitHeight + SH.HubStyle.pad * 2
  function size(b) { return b > 1073741824 ? (b / 1073741824).toFixed(1) + page.t(" ГБ", " GB") : Math.round(b / 1048576) + page.t(" МБ", " MB") }

  Column {
    id: col
    x: SH.HubStyle.pad; y: SH.HubStyle.pad
    width: parent.width - SH.HubStyle.pad * 2
    spacing: Style.space(10)
    SH.HubRow {
      width: parent.width
      icon: "\u{f04e6}"
      title: "Syncthing"
      hint: page.st.installed === false ? page.t("Не установлен", "Not installed") : page.st.running ? page.t("Работает", "Running") : page.t("Остановлен", "Stopped")
      fg: page.fg; fontFamily: page.ff
      Row {
        spacing: Style.space(6)
        SH.HubChip { visible: page.st.installed !== false && !page.st.running; icon: "\u{f040a}"; label: page.t("Запустить", "Start"); on: true; fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff; onClicked: page.mod.start() }
        SH.HubChip { visible: !!page.st.running; icon: "\u{f059f}"; label: page.t("Веб-интерфейс", "Web UI"); fg: page.fg; accent: page.accent; fontFamily: page.ff; onClicked: Quickshell.execDetached(["xdg-open", page.st.url]) }
      }
    }
    // this device's ID: what another device needs to add this one
    Rectangle {
      visible: !!page.st.myID
      width: parent.width; height: Style.space(44); radius: Style.space(10)
      color: SH.HubStyle.tint(page.fg, 0.05)
      Text { x: Style.space(12); anchors.verticalCenter: parent.verticalCenter; width: parent.width - copy.width - Style.space(30); elide: Text.ElideMiddle; text: page.t("ID этого компьютера: ", "This computer's ID: ") + (page.st.myID || ""); color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption }
      SH.HubChip {
        id: copy
        property bool done: false
        anchors.right: parent.right; anchors.rightMargin: Style.space(8); anchors.verticalCenter: parent.verticalCenter
        icon: done ? "\u{f012c}" : "\u{f018f}"; label: done ? page.t("Скопировано", "Copied") : page.t("Скопировать", "Copy"); h: Style.space(26)
        fg: page.fg; accent: page.accent; fontFamily: page.ff
        onClicked: { Quickshell.execDetached(["wl-copy", page.st.myID]); done = true }
      }
    }
    SH.HubCaption { visible: !!page.st.running; text: page.t("Папки", "Folders"); icon: "\u{f024b}"; fg: page.fg; fontFamily: page.ff }
    Text { visible: !!page.st.running && !(page.st.folders || []).length; text: page.t("Пока нет — добавьте папку в веб-интерфейсе", "None yet — add a folder in the web UI"); color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption }
    Repeater {
      model: page.st.folders || []
      delegate: Column {
        required property var modelData
        width: col.width
        spacing: Style.space(4)
        Item {
          width: parent.width; height: Style.space(20)
          Text { text: modelData.label + "  ·  " + modelData.path; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption + 1 }
          Text { anchors.right: parent.right; text: (modelData.paused ? page.t("пауза", "paused") : modelData.state === "idle" ? page.t("синхронно", "up to date") : modelData.state) + " · " + modelData.files + page.t(" файлов · ", " files · ") + page.size(modelData.bytes); color: Qt.darker(page.fg, 1.4); font.family: page.ff; font.pixelSize: Style.font.caption }
        }
        Rectangle { width: parent.width; height: Style.space(5); radius: height / 2; color: SH.HubStyle.tint(page.fg, 0.1)
          Rectangle { width: parent.width * modelData.completion / 100; height: parent.height; radius: height / 2; color: page.accent } }
      }
    }
    SH.HubCaption { visible: !!page.st.running; text: page.t("Устройства", "Devices"); icon: "\u{f011c}"; fg: page.fg; fontFamily: page.ff }
    Text { visible: !!page.st.running && !(page.st.devices || []).length; text: page.t("Только этот компьютер. На другом устройстве добавьте его ID выше.", "Only this computer. Add its ID above on another device."); color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption }
    Repeater {
      model: page.st.devices || []
      delegate: Row {
        required property var modelData
        spacing: Style.space(8)
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Style.space(8); height: width; radius: width / 2; color: modelData.connected ? "#30d158" : SH.HubStyle.tint(page.fg, 0.3) }
        Text { text: modelData.name + "  ·  " + (modelData.connected ? page.t("на связи", "connected") : page.t("не на связи", "offline")); color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption + 1 }
      }
    }
  }
}
