import QtQuick
import Quickshell.Widgets
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// "Now playing" for a widget turned 90°: the cover on top, then title,
// artist and the buttons, all upright.
Column {
  id: vp
  property var host: null
  readonly property var media: host ? host.media : null
  readonly property var player: media ? media.activePlayer : null
  readonly property bool playing: player !== null && !!player.isPlaying
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property string ff: Fonts.desk
  function act(name) { if (media) media.runAction(name, false, media.playerKey(player)) }
  property real coverSize: Style.space(130)
  width: Style.space(170)
  spacing: Style.space(8)

  Item {
    anchors.horizontalCenter: parent.horizontalCenter
    width: vp.coverSize; height: width
    ClippingRectangle {
      anchors.fill: parent
      radius: Style.space(14)
      color: "transparent"
      Image {
        id: art
        anchors.fill: parent
        source: vp.player ? (vp.player.trackArtUrl || "") : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
      }
    }
    Rectangle {
      anchors.fill: parent; radius: Style.space(14)
      visible: art.status !== Image.Ready
      color: SH.HubStyle.tint(vp.accent, 0.2)
      Text { anchors.centerIn: parent; text: "󰝚"; color: vp.accent; font.family: vp.ff; font.pixelSize: Style.space(42) }
    }
  }
  Text {
    width: parent.width
    horizontalAlignment: Text.AlignHCenter
    text: vp.player ? (vp.player.trackTitle || "") : ""
    color: vp.fg
    font.family: vp.ff; font.pixelSize: Style.font.body; font.bold: true
    wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
  }
  Text {
    width: parent.width
    horizontalAlignment: Text.AlignHCenter
    text: vp.player ? (vp.player.trackArtist || "") : ""
    color: Qt.darker(vp.fg, 1.35)
    font.family: vp.ff; font.pixelSize: Style.font.caption
    elide: Text.ElideRight
  }
  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Style.space(16)
    Repeater {
      model: [{ g: "󰒮", a: "previous" }, { g: vp.playing ? "󰏤" : "󰐊", a: "playPause" }, { g: "󰒭", a: "next" }]
      delegate: Text {
        required property var modelData
        text: modelData.g
        color: tm.containsMouse ? vp.accent : vp.fg
        font.family: vp.ff; font.pixelSize: Style.space(20)
        MouseArea { id: tm; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: vp.act(modelData.a) }
      }
    }
  }
}
