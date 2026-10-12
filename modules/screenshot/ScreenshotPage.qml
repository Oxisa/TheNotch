import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Widgets
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// Screenshot's page: the choices, the shutter, the latest shots.
Column {
  id: page
  property var mod: null
  spacing: SH.HubStyle.gap
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }

  component Choice: Row {
    property var items: []
    property string current: ""
    property string key: ""
    spacing: Style.space(6)
    Repeater {
      model: parent.items
      delegate: SH.HubChip {
        required property var modelData
        icon: modelData.icon || ""; label: modelData.label
        on: parent.current === String(modelData.id)
        subtle: true
        h: Style.space(30)
        fg: page.fg; accent: page.accent; fontFamily: page.ff
        onClicked: { var v = {}; v[parent.key] = modelData.id; page.mod.persist(v) }
      }
    }
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
      Text { text: page.t("Что снять", "Capture"); color: Qt.darker(page.fg, 1.4); font.family: page.ff; font.pixelSize: Style.font.caption; font.bold: true }
      Choice {
        key: "mode"; current: page.mod ? page.mod.mode : "region"
        items: [{ id: "region", icon: "\u{f019f}", label: page.t("Область", "Region") }, { id: "windows", icon: "\u{f05b2}", label: page.t("Окно", "Window") },
                { id: "fullscreen", icon: "\u{f0379}", label: page.t("Экран", "Screen") }, { id: "smart", icon: "\u{f0349}", label: page.t("Умный", "Smart") }]
      }
      Text { text: page.t("Что сделать со снимком", "Then"); color: Qt.darker(page.fg, 1.4); font.family: page.ff; font.pixelSize: Style.font.caption; font.bold: true }
      Choice {
        key: "action"; current: page.mod ? page.mod.action : "slurp"
        items: [{ id: "slurp", label: page.t("Копировать и сохранить", "Copy and save") }, { id: "copy", label: page.t("Только копировать", "Copy") },
                { id: "save", label: page.t("Только сохранить", "Save") }]
      }
      Text { text: page.t("Задержка", "Delay"); color: Qt.darker(page.fg, 1.4); font.family: page.ff; font.pixelSize: Style.font.caption; font.bold: true }
      Choice {
        key: "delay"; current: page.mod ? String(page.mod.delay) : "0"
        items: [{ id: 0, label: page.t("Сразу", "None") }, { id: 3, label: "3 с" }, { id: 5, label: "5 с" }, { id: 10, label: "10 с" }]
      }
      SH.HubChip {
        anchors.horizontalCenter: parent.horizontalCenter
        icon: "\u{f0100}"; label: page.t("Снять", "Take it")
        on: true
        h: Style.space(36)
        fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
        onClicked: page.mod.shoot()
      }
    }
  }

  // the latest shots: click to open in the editor
  FolderListModel {
    id: shots
    folder: page.mod ? "file://" + page.mod.folder : ""
    nameFilters: ["screenshot-*.png"]
    sortField: FolderListModel.Time
    showDirs: false
  }
  Item {
    width: page.width; height: Style.space(26)
    Text { anchors.verticalCenter: parent.verticalCenter; text: page.t("Последние", "Latest"); color: Qt.darker(page.fg, 1.4); font.family: page.ff; font.pixelSize: Style.font.caption; font.bold: true }
    SH.HubChip {
      anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
      icon: "\u{f0256}"; label: page.t("Папка", "Folder"); h: Style.space(24)
      fg: page.fg; accent: page.accent; fontFamily: page.ff
      onClicked: Quickshell.execDetached(["xdg-open", page.mod.folder])
    }
  }
  Flow {
    width: page.width
    spacing: Style.space(6)
    Repeater {
      model: shots
      delegate: ClippingRectangle {
        id: shot
        required property string filePath
        required property int index
        visible: index < 6
        width: (page.width - Style.space(12)) / 3; height: width * 0.6
        radius: Style.space(10)
        color: SH.HubStyle.tint(page.fg, 0.06)
        border.width: sm.containsMouse ? 2 : 0; border.color: page.accent
        Image { anchors.fill: parent; source: "file://" + shot.filePath; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 320 }
        MouseArea {
          id: sm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          onClicked: function(m) {
            if (m.button === Qt.RightButton) Quickshell.execDetached(["bash", "-c", "wl-copy --type image/png < \"$0\"", shot.filePath])
            else { page.mod.notch.expanded = false; Quickshell.execDetached(["bash", "-c", "${OMARCHY_SCREENSHOT_EDITOR:-tensaku-edit} \"$0\"", shot.filePath]) }
          }
        }
      }
    }
  }
  Text {
    text: page.t("Клик — открыть в редакторе, правый клик — скопировать", "Click to edit, right-click to copy")
    color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption - 1
  }
}
