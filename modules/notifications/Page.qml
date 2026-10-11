import QtQuick
import Quickshell.Widgets
import qs.Commons
import "../../../osia.soundhub" as SH

// History of notifications, newest first, with Do Not Disturb and Clear.
Column {
  id: page
  property var mod: null
  spacing: SH.HubStyle.gap

  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Style.font.family

  SH.HubCard {
    width: parent.width
    height: dndRow.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    SH.HubRow {
      id: dndRow
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      title: page.mod ? page.mod.t("dnd") : ""
      hint: page.mod ? page.mod.t("dndHint") : ""
      fg: page.fg; fontFamily: page.ff
      SH.HubSwitch {
        checked: page.mod ? page.mod.dnd : false
        fg: page.fg; accent: page.accent; ink: page.bgc
        onToggled: page.mod.setDnd(!checked)
      }
    }
  }

  SH.HubCaption {
    text: page.mod ? page.mod.t("title") : ""
    icon: "󰂚"
    fg: page.fg; fontFamily: page.ff
    SH.HubChip {
      visible: page.mod && page.mod.history.length > 0
      icon: "󰆴"
      label: page.mod ? page.mod.t("clear") : ""
      h: Style.space(26)
      fg: page.fg; accent: page.accent; fontFamily: page.ff
      onClicked: page.mod.clearHistory()
    }
  }

  Text {
    visible: !page.mod || page.mod.history.length === 0
    width: parent.width
    horizontalAlignment: Text.AlignHCenter
    topPadding: Style.space(18); bottomPadding: Style.space(18)
    text: page.mod ? page.mod.t("empty") : ""
    color: Qt.darker(page.fg, 1.6)
    font.family: page.ff; font.pixelSize: Style.font.body
  }

  Repeater {
    model: page.mod ? page.mod.history : []
    delegate: SH.HubCard {
      id: card
      required property var modelData
      width: page.width
      height: Math.max(icon.height, texts.implicitHeight) + SH.HubStyle.pad * 2
      fg: page.fg; accent: page.accent
      readonly property string iconSrc: page.mod ? page.mod.iconFor(modelData) : ""
      readonly property string img: page.mod ? page.mod.imageFor(modelData) : ""

      ClippingRectangle {
        id: icon
        x: SH.HubStyle.pad; y: SH.HubStyle.pad
        width: Style.space(34); height: width
        radius: card.img ? Style.space(8) : 0
        color: "transparent"
        Image {
          id: pic
          anchors.fill: parent
          source: card.img || card.iconSrc
          fillMode: card.img ? Image.PreserveAspectCrop : Image.PreserveAspectFit
          sourceSize: Qt.size(68, 68)
        }
        Text {
          anchors.centerIn: parent
          visible: pic.status !== Image.Ready
          text: card.modelData.glyph || "󰂚"
          color: page.accent
          font.family: page.ff; font.pixelSize: Style.space(20)
        }
      }
      Column {
        id: texts
        x: icon.x + icon.width + Style.space(12); y: SH.HubStyle.pad
        width: parent.width - x - SH.HubStyle.pad
        spacing: Style.space(3)
        Text {
          width: parent.width
          text: String(card.modelData.app || "") + "  ·  " + (page.mod ? (page.mod.tick, page.mod.ago(card.modelData.timestamp || 0)) : "")
                + (card.modelData.count > 1 ? "  ·  ×" + card.modelData.count : "")
          color: Qt.darker(page.fg, 1.6)
          font.family: page.ff; font.pixelSize: Style.font.caption - 1
          elide: Text.ElideRight
        }
        Text {
          width: parent.width
          text: page.mod ? page.mod.plain(card.modelData.summary) : ""
          color: page.fg
          font.family: page.ff; font.pixelSize: Style.font.body; font.bold: true
          elide: Text.ElideRight
        }
        Text {
          width: parent.width
          visible: text !== ""
          text: page.mod ? page.mod.plain(card.modelData.body) : ""
          color: Qt.darker(page.fg, 1.3)
          font.family: page.ff; font.pixelSize: Style.font.caption
          wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight
        }
      }
    }
  }
}
