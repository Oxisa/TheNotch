import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Commons
import "../../../osia.soundhub" as SH

// Home's page, laid out like caelestia's dashboard:
//   [ weather ][ profile           ][ player ]
//   [ date ][ calendar ][ resources ][ (tall) ]
Item {
  id: page
  property var mod: null
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Style.font.family
  function t(a, b) { return mod ? mod.t(a, b) : b }
  readonly property var weather: mod ? mod.moduleById("weather") : null
  readonly property var sys: mod ? mod.moduleById("system") : null
  readonly property var sound: mod ? mod.moduleById("soundhub") : null
  readonly property var d: sys ? sys.data : ({})
  readonly property var account: mod ? mod.moduleById("account") : null

  readonly property real gap: Style.space(10)
  readonly property real topH: Style.space(124)
  readonly property real lowH: Style.space(236)
  readonly property real mediaW: Style.space(210)
  readonly property real dateW: Style.space(92)
  readonly property real resW: Style.space(104)
  readonly property real leftW: width - mediaW - gap
  implicitHeight: topH + gap + lowH

  component Card: Rectangle {
    radius: SH.HubStyle.radius + Style.space(4)
    color: SH.HubStyle.tint(page.fg, 0.05)
  }

  property date now: new Date()
  Timer { interval: 1000; running: page.visible; repeat: true; onTriggered: page.now = new Date() }

  // ------------------------------------------------------------ weather
  Card {
    id: wCard
    width: Math.round(page.leftW * 0.42); height: page.topH
    readonly property var n: page.weather ? page.weather.now : null
    Row {
      anchors.centerIn: parent
      spacing: Style.space(14)
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: wCard.n ? page.weather.glyph(wCard.n.code, wCard.n.day) : "\u{f0590}"
        color: page.accent
        font.family: page.ff; font.pixelSize: Style.space(56)
      }
      Column {
        anchors.verticalCenter: parent.verticalCenter
        Text {
          text: wCard.n ? page.weather.deg(wCard.n.temp) : "—"
          color: page.fg
          font.family: page.ff; font.pixelSize: Style.space(34); font.bold: true
        }
        Text {
          text: wCard.n ? page.weather.words(wCard.n.code) : page.t("Выберите город", "Pick a city")
          color: Qt.darker(page.fg, 1.3)
          font.family: page.ff; font.pixelSize: Style.font.caption
        }
      }
    }
    MouseArea { anchors.fill: parent; enabled: !wCard.n; cursorShape: Qt.PointingHandCursor; onClicked: page.mod.notch.openSettings("weather") }
  }

  // ------------------------------------------------------------ profile
  Card {
    x: wCard.width + page.gap
    width: page.leftW - wCard.width - page.gap; height: page.topH
    Row {
      anchors.verticalCenter: parent.verticalCenter
      x: Style.space(18)
      spacing: Style.space(18)
      ClippingRectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(84); height: width; radius: width / 2
        color: SH.HubStyle.tint(page.accent, 0.25)
        Image {
          anchors.fill: parent
          source: page.account ? page.account.face : "file://" + Quickshell.env("HOME") + "/.face"
          cache: false
          fillMode: Image.PreserveAspectCrop
          sourceSize.width: 200
          asynchronous: true
        }
      }
      Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(6)
        Text {
          visible: !!page.account
          text: page.account ? page.account.displayName : ""
          color: page.fg
          font.family: page.ff; font.pixelSize: Style.font.body + 3; font.bold: true
        }
        Repeater {
          model: [{ g: "\u{f033d}", v: page.mod ? page.mod.osName : "" }, { g: "\u{f0379}", v: "Hyprland" },
                  { g: "\u{f0150}", v: page.mod ? page.mod.upText() : "" }]
          delegate: Row {
            required property var modelData
            spacing: Style.space(10)
            Text { text: modelData.g; color: page.accent; font.family: page.ff; font.pixelSize: Style.font.body + 1 }
            Text { text: modelData.v; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.body }
          }
        }
      }
    }
  }

  // ------------------------------------------------------------ date
  Card {
    id: dCard
    y: page.topH + page.gap
    width: page.dateW; height: page.lowH
    Column {
      anchors.centerIn: parent
      spacing: Style.space(4)
      Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatTime(page.now, "HH"); color: page.accent; font.family: page.ff; font.pixelSize: Style.space(40); font.bold: true }
      Text { anchors.horizontalCenter: parent.horizontalCenter; text: "•••"; color: page.accent; font.family: page.ff; font.pixelSize: Style.font.body }
      Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatTime(page.now, "mm"); color: page.accent; font.family: page.ff; font.pixelSize: Style.space(40); font.bold: true }
      Item { width: 1; height: Style.space(8) }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: page.now.toLocaleDateString(Qt.locale(page.mod && page.mod.ru ? "ru_RU" : "en_US"), "ddd, d")
        color: Qt.darker(page.fg, 1.25)
        font.family: page.ff; font.pixelSize: Style.font.caption
      }
    }
  }

  // ------------------------------------------------------------ calendar
  Card {
    x: page.dateW + page.gap; y: page.topH + page.gap
    width: page.leftW - page.dateW - page.resW - page.gap * 2; height: page.lowH
    Calendar { anchors.fill: parent; anchors.margins: Style.space(14); ru: page.mod ? page.mod.ru : true }
  }

  // ------------------------------------------------------------ resources
  Card {
    x: page.leftW - page.resW; y: page.topH + page.gap
    width: page.resW; height: page.lowH
    Row {
      anchors.centerIn: parent
      spacing: Style.space(14)
      Repeater {
        model: [{ g: "\u{f061a}", v: (page.d.cpu || 0) / 100 },
                { g: "\u{f035b}", v: page.d.ramTotal ? page.d.ramUsed / page.d.ramTotal : 0 },
                { g: "\u{f02ca}", v: page.d.disks && page.d.disks.length ? page.d.disks[0].used / page.d.disks[0].total : 0 }]
        delegate: Column {
          required property var modelData
          spacing: Style.space(8)
          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Style.space(8); height: page.lowH - Style.space(64); radius: width / 2
            color: SH.HubStyle.tint(page.fg, 0.10)
            Rectangle {
              anchors.bottom: parent.bottom
              width: parent.width; radius: width / 2
              height: Math.max(width, parent.height * Math.min(1, modelData.v))
              color: page.accent
              Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            }
          }
          Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.g; color: Qt.darker(page.fg, 1.2); font.family: page.ff; font.pixelSize: Style.font.body }
        }
      }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.mod.notch.openModule("system") }
  }

  // ------------------------------------------------------------ player
  Card {
    id: mCard
    x: page.leftW + page.gap
    width: page.mediaW; height: page.implicitHeight
    readonly property var media: page.sound ? page.sound.media : null
    readonly property var player: media ? media.activePlayer : null
    readonly property bool hasTrack: player !== null && !!(player.trackTitle || player.trackArtist)
    readonly property bool playing: player !== null && !!player.isPlaying
    function act(name) { if (media) media.runAction(name, false, media.playerKey(player)) }
    Column {
      anchors.centerIn: parent
      width: parent.width - Style.space(28)
      spacing: Style.space(8)
      ClippingRectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: Style.space(140); height: width; radius: width / 2
        color: SH.HubStyle.tint(page.accent, 0.18)
        Image {
          id: art
          anchors.fill: parent
          source: mCard.player ? (mCard.player.trackArtUrl || "") : ""
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          RotationAnimator on rotation { from: 0; to: 360; duration: 20000; loops: Animation.Infinite; running: mCard.playing }
        }
        Text { anchors.centerIn: parent; visible: art.status !== Image.Ready; text: "󰝚"; color: page.accent; font.family: page.ff; font.pixelSize: Style.space(44) }
      }
      Item { width: 1; height: Style.space(4) }
      Text {
        width: parent.width; horizontalAlignment: Text.AlignHCenter
        text: mCard.hasTrack ? mCard.player.trackTitle : page.t("Ничего не играет", "Nothing playing")
        color: page.accent
        font.family: page.ff; font.pixelSize: Style.font.body; font.bold: true
        elide: Text.ElideRight
      }
      Text {
        width: parent.width; horizontalAlignment: Text.AlignHCenter
        visible: mCard.hasTrack && !!mCard.player.trackAlbum
        text: mCard.player ? (mCard.player.trackAlbum || "") : ""
        color: Qt.darker(page.fg, 1.4)
        font.family: page.ff; font.pixelSize: Style.font.caption - 1
        elide: Text.ElideRight
      }
      Text {
        width: parent.width; horizontalAlignment: Text.AlignHCenter
        text: mCard.hasTrack ? (mCard.player.trackArtist || "") : ""
        color: Qt.darker(page.fg, 1.15)
        font.family: page.ff; font.pixelSize: Style.font.caption
        elide: Text.ElideRight
      }
      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(18)
        opacity: mCard.hasTrack ? 1 : 0.4
        Repeater {
          model: [{ g: "󰒮", a: "previous" }, { g: mCard.playing ? "󰏤" : "󰐊", a: "playPause" }, { g: "󰒭", a: "next" }]
          delegate: Text {
            required property var modelData
            text: modelData.g
            color: bm.containsMouse ? page.accent : page.fg
            font.family: page.ff; font.pixelSize: Style.space(22)
            MouseArea { id: bm; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: mCard.act(modelData.a) }
          }
        }
      }
    }
  }
}
