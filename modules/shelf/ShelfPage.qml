import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// The Shelf tool: what was dropped, newest first. Drag a card out into an
// app (a real system drag), or use its buttons. Drop more onto this page or
// onto the closed notch.
Column {
  id: page
  property var mod: null
  spacing: Style.space(10)
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }

  Item {
    width: page.width; height: Style.space(28)
    Text { anchors.verticalCenter: parent.verticalCenter; text: page.t("Перетащите сюда или на чёлку · карточку — обратно в приложение", "Drop here or on the notch · drag a card back into an app"); color: Qt.darker(page.fg, 1.5); font.family: page.ff; font.pixelSize: Style.font.caption }
    SH.HubChip { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; visible: page.mod && page.mod.items.length > 0; icon: "\u{f0a7a}"; label: page.t("Очистить", "Clear"); subtle: true; h: Style.space(26); fg: page.fg; accent: page.accent; fontFamily: page.ff; onClicked: page.mod.clear() }
  }
  Rectangle {
    width: page.width
    height: Math.max(Style.space(140), grid.implicitHeight + Style.space(20))
    radius: SH.HubStyle.radius + Style.space(2)
    color: drop.containsDrag ? SH.HubStyle.tint(page.accent, 0.18) : SH.HubStyle.tint(page.fg, 0.04)
    border.width: drop.containsDrag ? 2 : 1; border.color: drop.containsDrag ? page.accent : SH.HubStyle.tint(page.fg, 0.1)
    DropArea { id: drop; anchors.fill: parent; onDropped: function(ev) { page.mod.take(ev.urls, ev.text); ev.acceptProposedAction() } }
    Text { visible: !page.mod || page.mod.items.length === 0; anchors.centerIn: parent; text: "\u{f0120}  " + page.t("Полка пуста", "The shelf is empty"); color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.body }
    Flow {
      id: grid
      x: Style.space(10); y: Style.space(10)
      width: parent.width - Style.space(20)
      spacing: Style.space(8)
      Repeater {
        model: page.mod ? page.mod.items : []
        delegate: Rectangle {
          id: card
          required property var modelData
          width: Style.space(140); height: Style.space(150)
          radius: Style.space(12)
          color: SH.HubStyle.tint(page.fg, cm.containsMouse ? 0.12 : 0.07)
          // a real drag out into other apps
          Drag.dragType: Drag.Automatic
          Drag.supportedActions: Qt.CopyAction
          Drag.mimeData: card.modelData.kind === "file" ? { "text/uri-list": "file://" + encodeURI(card.modelData.value) + "\r\n", "text/plain": card.modelData.value }
                                                        : { "text/plain": card.modelData.value }
          Drag.active: cm.drag.active
          ClippingRectangle {
            x: Style.space(8); y: Style.space(8); width: parent.width - Style.space(16); height: Style.space(84); radius: Style.space(8)
            color: SH.HubStyle.tint(page.fg, 0.06)
            Image { anchors.fill: parent; visible: page.mod.isImage(card.modelData); source: visible ? "file://" + card.modelData.value : ""; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 260 }
            IconImage {
              anchors.centerIn: parent; width: Style.space(40); height: width
              visible: card.modelData.kind === "file" && !page.mod.isImage(card.modelData)
              source: Quickshell.iconPath(/\/$|^[^.]*$/.test(card.modelData.name) ? "folder" : "text-x-generic", true)
            }
            Text {
              visible: card.modelData.kind !== "file"
              anchors.fill: parent; anchors.margins: Style.space(6)
              text: card.modelData.kind === "url" ? "\u{f0337}\n" + card.modelData.name : card.modelData.value
              wrapMode: Text.Wrap; elide: Text.ElideRight; maximumLineCount: 5
              color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption - 1
            }
          }
          Text { x: Style.space(8); y: Style.space(98); width: parent.width - Style.space(16); elide: Text.ElideMiddle; text: card.modelData.name; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption }
          MouseArea {
            id: cm
            anchors.fill: parent; hoverEnabled: true
            drag.target: card; drag.threshold: 6
            cursorShape: Qt.OpenHandCursor
            onReleased: { card.x = card.x; card.Drag.drop() }
            onDoubleClicked: page.mod.open(card.modelData)
          }
          Row {
            anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: Style.space(6)
            spacing: Style.space(4)
            visible: cm.containsMouse || hoverRow.hovered
            HoverHandler { id: hoverRow }
            component Mini: Rectangle {
              property string glyph: ""
              signal clicked()
              width: Style.space(24); height: width; radius: width / 2
              color: mm.containsMouse ? SH.HubStyle.tint(page.accent, 0.5) : SH.HubStyle.tint(page.fg, 0.14)
              Text { anchors.centerIn: parent; text: parent.glyph; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption }
              MouseArea { id: mm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
            }
            Mini { glyph: "\u{f03cc}"; onClicked: page.mod.open(card.modelData) }
            Mini { visible: card.modelData.kind === "file"; glyph: "\u{f024b}"; onClicked: page.mod.reveal(card.modelData) }
            Mini { glyph: "\u{f018f}"; onClicked: page.mod.copy(card.modelData) }
            Mini { glyph: "\u{f0156}"; onClicked: page.mod.remove(card.modelData.id) }
          }
        }
      }
    }
  }
}
