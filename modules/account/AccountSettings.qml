import QtQuick
import Quickshell.Widgets
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// Settings → Account: the picture (one button: the system's file chooser)
// and the name.
Column {
  id: page
  property var mod: null
  spacing: SH.HubStyle.gap
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }

  SH.HubCard {
    width: page.width
    height: top.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    Row {
      id: top
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      spacing: Style.space(22)
      ClippingRectangle {
        width: Style.space(120); height: width; radius: width / 2
        color: SH.HubStyle.tint(page.accent, 0.25)
        Image { anchors.fill: parent; source: page.mod ? page.mod.face : ""; fillMode: Image.PreserveAspectCrop; cache: false; sourceSize.width: 256 }
      }
      Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(10)
        Text { text: page.mod ? page.mod.displayName : ""; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.title + 2; font.bold: true }
        Text { text: page.mod ? "@" + page.mod.user : ""; color: Qt.darker(page.fg, 1.5); font.family: page.ff; font.pixelSize: Style.font.caption }
        Row {
          spacing: Style.space(6)
          SH.HubChip {
            icon: "\u{f0100}"; label: page.t("Выбрать фото…", "Choose a picture…")
            on: true
            fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
            onClicked: page.mod.pickFile()
          }
          SH.HubChip {
            icon: "\u{f054c}"; label: page.t("Вернуть прежнее", "Undo")
            fg: page.fg; accent: page.accent; fontFamily: page.ff
            onClicked: page.mod.run(["undo"])
          }
        }
      }
    }
  }
  SH.HubCard {
    width: page.width
    height: nm.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    Column {
      id: nm
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      spacing: Style.space(8)
      SH.HubRow { title: page.t("Как вас называть", "Your name"); hint: page.t("Показывается на «Главной»", "Shown on Home"); fg: page.fg; fontFamily: page.ff }
      SH.HubField {
        width: parent.width
        icon: "\u{f0009}"
        placeholderText: page.mod ? page.mod.user : ""
        text: page.mod ? String(page.mod.opt("name", "")) : ""
        fg: page.fg; accent: page.accent; fontFamily: page.ff
        onEditingFinished: page.mod.persist({ name: text.trim() })
      }
    }
  }
}
