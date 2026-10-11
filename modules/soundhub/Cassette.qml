import QtQuick
import Quickshell.Services.Mpris
import qs.Commons
import "../../../osia.soundhub" as SH
import "../../DeskStyle.js" as DS

// "Now playing" as a cassette: a label with the title and artist, two reels
// that turn while it plays — tape winds from the left reel to the right one as
// the track goes on — and play/prev/next under the window. Clicking the label
// toggles play. Looks after rover-001/whimsy's cassette (MIT); no code taken.
Rectangle {
  id: k
  property var host: null
  property bool editing: false
  readonly property var media: host ? host.media : null
  readonly property var player: media ? media.activePlayer : null
  readonly property bool hasTrack: player !== null && !!(player.trackTitle || player.trackArtist)
  readonly property bool playing: player !== null && !!player.isPlaying
  readonly property bool deskShown: hasTrack || editing
  property var deskStyle: ({})
  readonly property color fg: DS.fg(deskStyle, Color.foreground)
  readonly property color accent: DS.accent(deskStyle, Color.accent)
  readonly property color bgc: Color.background
  readonly property string ff: Style.font.family

  property real pos: player ? player.position : 0
  readonly property real len: player && player.lengthSupported ? player.length : 0
  readonly property real progress: len > 0 ? Math.max(0, Math.min(1, pos / len)) : 0.35
  Timer {
    interval: 1000; repeat: true; running: k.playing && k.visible
    onTriggered: if (k.player) { k.player.positionChanged(); k.pos = k.player.position }
  }
  function act(name) { if (media) media.runAction(name, false, media.playerKey(player)) }

  width: Style.space(360); height: Style.space(228)
  radius: DS.radius(deskStyle, Style.space(18))
  topLeftRadius: DS.corner(deskStyle, "tl", Style.space(18))
  topRightRadius: DS.corner(deskStyle, "tr", Style.space(18))
  bottomLeftRadius: DS.corner(deskStyle, "bl", Style.space(18))
  bottomRightRadius: DS.corner(deskStyle, "br", Style.space(18))
  color: DS.bg(deskStyle, bgc, accent, host ? Number(host.opt("deskOpacity", 0.85)) : 0.85)
  border.width: 1
  border.color: DS.border(deskStyle, Color.foreground)

  // screws in the corners
  Repeater {
    model: [[12, 12], [1, 0], [0, 1], [1, 1]]
    delegate: Rectangle {
      required property var modelData
      required property int index
      width: Style.space(7); height: width; radius: width / 2
      color: SH.HubStyle.tint(k.fg, 0.25)
      x: index === 0 || index === 2 ? Style.space(10) : k.width - width - Style.space(10)
      y: index < 2 ? Style.space(10) : k.height - height - Style.space(10)
    }
  }

  // the label
  Rectangle {
    id: label
    x: Style.space(26); y: Style.space(20)
    width: parent.width - Style.space(52); height: Style.space(150)
    radius: Style.space(10)
    color: SH.HubStyle.tint(k.accent, 0.18)
    border.width: 1; border.color: SH.HubStyle.tint(k.accent, 0.35)
    Column {
      x: Style.space(14); y: Style.space(8)
      width: parent.width - Style.space(28)
      Text {
        width: parent.width
        text: k.player ? (k.player.trackTitle || "") : (k.host && k.host.ru ? "Сейчас играет" : "Now playing")
        color: k.fg
        font.family: k.ff; font.pixelSize: Style.font.body; font.bold: true
        elide: Text.ElideRight
      }
      Text {
        width: parent.width
        text: k.player ? (k.player.trackArtist || "") : ""
        color: Qt.darker(k.fg, 1.35)
        font.family: k.ff; font.pixelSize: Style.font.caption
        elide: Text.ElideRight
      }
    }
    // the window with the two reels
    Rectangle {
      id: win
      anchors.horizontalCenter: parent.horizontalCenter
      y: Style.space(56)
      width: parent.width - Style.space(60); height: Style.space(76)
      radius: height / 2
      color: Qt.rgba(0, 0, 0, 0.45)
      border.width: 1; border.color: SH.HubStyle.tint(k.fg, 0.12)
      component Reel: Item {
        id: reel
        property real amount: 0.5                   // how much tape is on it, 0..1
        width: Style.space(64); height: width
        Rectangle {                                  // the tape on the reel
          anchors.centerIn: parent
          width: Style.space(26) + reel.amount * Style.space(36); height: width; radius: width / 2
          color: Qt.rgba(0.17, 0.12, 0.10, 0.95)
        }
        Item {
          id: hub
          anchors.centerIn: parent
          width: Style.space(26); height: width
          Rectangle { anchors.fill: parent; radius: width / 2; color: k.bgc; border.width: 2; border.color: k.accent }
          Repeater {
            model: 3
            delegate: Rectangle {
              required property int index
              width: Style.space(3); height: Style.space(10); radius: width / 2
              x: hub.width / 2 - width / 2; y: Style.space(2)
              color: k.accent
              transform: Rotation { origin.x: Style.space(1.5); origin.y: hub.height / 2 - Style.space(2); angle: index * 120 }
            }
          }
          RotationAnimator on rotation { from: 0; to: 360; duration: 2400; loops: Animation.Infinite; running: k.playing }
        }
      }
      Reel { anchors.verticalCenter: parent.verticalCenter; x: Style.space(18); amount: 1 - k.progress }
      Reel { anchors.verticalCenter: parent.verticalCenter; x: parent.width - width - Style.space(18); amount: k.progress }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: k.act("playPause") }
  }

  // transport
  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom; anchors.bottomMargin: Style.space(12)
    spacing: Style.space(18)
    Repeater {
      model: [{ g: "󰒮", a: "previous" }, { g: k.playing ? "󰏤" : "󰐊", a: "playPause" }, { g: "󰒭", a: "next" }]
      delegate: Text {
        required property var modelData
        text: modelData.g
        color: tm.containsMouse ? k.accent : k.fg
        font.family: k.ff; font.pixelSize: Style.space(20)
        MouseArea { id: tm; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: k.act(modelData.a) }
      }
    }
  }
}
