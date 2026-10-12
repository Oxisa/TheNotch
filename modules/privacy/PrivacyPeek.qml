import QtQuick
import Quickshell.Widgets
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// The hover card behind the dots: which apps use the mic and the camera.
Column {
  id: pk
  property var mod: null
  spacing: Style.space(8)
  readonly property color fg: Color.foreground
  readonly property string ff: Fonts.ui
  component Group: Column {
    id: g
    property string kind: "mic"
    readonly property var apps: pk.mod ? (kind === "mic" ? pk.mod.mic : pk.mod.cam) : []
    visible: apps.length > 0
    width: pk.width
    spacing: Style.space(6)
    Row {
      spacing: Style.space(6)
      Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Style.space(8); height: width; radius: width / 2; color: g.kind === "mic" ? pk.mod.micColor : pk.mod.camColor }
      Text { text: g.kind === "mic" ? pk.mod.t("Микрофон", "Microphone") : pk.mod.t("Камера", "Camera"); color: Qt.darker(pk.fg, 1.4); font.family: pk.ff; font.pixelSize: Style.font.caption; font.bold: true }
    }
    Repeater {
      model: g.apps
      delegate: Row {
        required property var modelData
        spacing: Style.space(8)
        IconImage { width: Style.space(22); height: width; source: pk.mod.iconOf(modelData); visible: source != "" }
        Text { anchors.verticalCenter: parent.verticalCenter; text: pk.mod.nameOf(modelData); color: pk.fg; font.family: pk.ff; font.pixelSize: Style.font.body }
      }
    }
  }
  Group { kind: "mic" }
  Group { kind: "cam" }
}
