import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../DeskStyle.js" as DS
import "../../fonts"

// A book on the desktop: the cover, then the title, the author and how far
// it's read (Foliate's progress). Turned 90°, the cover stands on top of the
// text. Click opens it in Foliate; right-click or the wheel moves to another
// book.
Rectangle {
  id: card
  property var mod: null
  property string deskId: ""
  readonly property var fd: mod ? mod.feed(deskId) : null
  property bool editing: false
  property bool deskVertical: false
  property var deskStyle: ({})
  property real deskScale: 1
  readonly property bool deskShown: (fd !== null && fd.count > 0) || editing
  readonly property var book: fd ? fd.current : null

  readonly property real k: deskScale
  readonly property real ww: (fd ? fd.size : 380) * k
  readonly property real padding: Style.space(14) * k
  readonly property real coverW: deskVertical ? ww - padding * 2 : ww * 0.3
  readonly property real coverH: deskVertical ? coverW * 1.25 : coverW * 1.5
  readonly property color fg: DS.fg(deskStyle, Color.foreground)
  readonly property color acc: DS.accent(deskStyle, Color.accent)
  readonly property string titleFamily: mod && fd ? mod.fontOf(fd.titleFont, Fonts.desk) : Fonts.desk
  readonly property string authorFamily: mod && fd ? mod.fontOf(fd.authorFont, Fonts.desk) : Fonts.desk

  width: ww
  height: deskVertical ? padding * 2 + coverH + Style.space(12) * k + info.implicitHeight : padding * 2 + Math.max(coverH, info.implicitHeight)
  radius: DS.radius(deskStyle, SH.HubStyle.radius + Style.space(4))
  topLeftRadius: DS.corner(deskStyle, "tl", SH.HubStyle.radius + Style.space(4))
  topRightRadius: DS.corner(deskStyle, "tr", SH.HubStyle.radius + Style.space(4))
  bottomLeftRadius: DS.corner(deskStyle, "bl", SH.HubStyle.radius + Style.space(4))
  bottomRightRadius: DS.corner(deskStyle, "br", SH.HubStyle.radius + Style.space(4))
  color: DS.bg(deskStyle, Color.background, Color.accent, 0.85)
  border.width: 1
  border.color: DS.border(deskStyle, Color.foreground)

  // the cover (or a plain one with the title's first letter)
  ClippingRectangle {
    id: cover
    x: card.padding; y: card.padding
    width: card.coverW; height: card.coverH
    radius: Style.space(6) * card.k
    color: SH.HubStyle.tint(card.acc, 0.25)
    layer.enabled: true
    layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 0.6; shadowOpacity: 0.45; shadowVerticalOffset: 2 }
    Image {
      id: img
      anchors.fill: parent
      fillMode: card.deskVertical ? Image.PreserveAspectCrop : Image.PreserveAspectCrop
      asynchronous: true
      sourceSize.width: Math.round(card.coverW * 2)
      source: card.book && card.book.cover && card.mod ? card.mod.url(card.book.cover) : ""
      opacity: status === Image.Ready ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 300 } }
    }
    Text {
      visible: img.status !== Image.Ready
      anchors.centerIn: parent
      text: card.book ? card.book.title.charAt(0).toUpperCase() : "\u{f00be}"
      color: card.fg; font.family: card.titleFamily; font.pixelSize: card.coverW * 0.4; font.bold: true
    }
  }

  // title, author, progress
  Column {
    id: info
    x: card.deskVertical ? card.padding : cover.x + cover.width + Style.space(14) * card.k
    y: card.deskVertical ? cover.y + cover.height + Style.space(12) * card.k : card.padding + Math.max(0, (card.coverH - implicitHeight) / 2)
    width: card.deskVertical ? card.ww - card.padding * 2 : card.ww - x - card.padding
    spacing: Style.space(6) * card.k
    Text {
      width: parent.width
      wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight
      horizontalAlignment: card.deskVertical ? Text.AlignHCenter : Text.AlignLeft
      text: card.book ? card.book.title : (card.mod ? card.mod.t("Нет книг в выбранных папках", "No books in the chosen folders") : "")
      color: card.fg; font.family: card.titleFamily; font.pixelSize: Style.space(19) * card.k; font.bold: true
    }
    Text {
      visible: !!card.fd && card.fd.showAuthor && !!card.book && card.book.author !== ""
      width: parent.width
      wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
      horizontalAlignment: card.deskVertical ? Text.AlignHCenter : Text.AlignLeft
      text: card.book ? card.book.author : ""
      color: Qt.rgba(card.fg.r, card.fg.g, card.fg.b, 0.7); font.family: card.authorFamily; font.pixelSize: Style.space(14) * card.k
    }
    Item { width: 1; height: Style.space(4) * card.k; visible: progress.visible }
    Column {
      id: progress
      visible: !!card.fd && card.fd.showProgress && !!card.book
      width: parent.width
      spacing: Style.space(4) * card.k
      readonly property real value: card.book && card.book.progress !== null ? card.book.progress : 0
      Rectangle {
        width: parent.width; height: Style.space(5) * card.k; radius: height / 2
        color: Qt.rgba(card.fg.r, card.fg.g, card.fg.b, 0.12)
        Rectangle {
          width: Math.max(height, parent.width * progress.value); height: parent.height; radius: height / 2
          visible: progress.value > 0
          color: card.acc
          Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        }
      }
      Text {
        width: parent.width
        horizontalAlignment: card.deskVertical ? Text.AlignHCenter : Text.AlignLeft
        text: !card.book ? "" : card.book.progress === null ? (card.mod ? card.mod.t("Не начата", "Not started") : "")
              : Math.round(card.book.progress * 100) + "%"
        color: Qt.rgba(card.fg.r, card.fg.g, card.fg.b, 0.6); font.family: Fonts.desk; font.pixelSize: Style.space(12) * card.k
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: function(m) { if (m.button === Qt.RightButton) card.fd.step(1); else card.mod.open(card.book) }
    onWheel: function(e) { card.fd.step(e.angleDelta.y > 0 ? -1 : 1) }
  }
}
