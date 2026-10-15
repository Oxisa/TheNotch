import QtQuick
import QtQuick.Effects
import QtMultimedia
import Quickshell.Widgets
import qs.Commons
import "../../DeskStyle.js" as DS
import "../../fonts"

// Gallery on the desktop. Carousel: the current file in the middle, the
// previous and next ones blurred at the sides (click them to step). Single:
// one picture with an effect. Click the middle one to show the file in its
// folder and open it; right-click or the wheel steps. Videos play muted.
Item {
  id: w
  property var mod: null
  property string deskId: ""                  // set by the window: which widget (the main one or a copy)
  readonly property var fd: mod ? mod.feed(deskId) : null   // its slideshow (GalleryFeed)
  property bool editing: false
  property var deskStyle: ({})
  property real deskScale: 1
  readonly property bool deskShown: (fd !== null && fd.count > 0) || editing

  readonly property bool carousel: !fd || fd.look !== "single"
  readonly property real ww: (fd ? fd.size : 480) * deskScale
  readonly property real hh: ww * (carousel ? 0.5 : 0.62)
  readonly property real rad: DS.radius(deskStyle, Style.space(16))
  readonly property real pad: Style.space(10) * deskScale
  width: ww + pad * 2
  height: hh + pad * 2

  // the card behind (none unless chosen under Style)
  Rectangle {
    anchors.fill: parent
    radius: w.rad + w.pad / 2
    color: DS.bg(w.deskStyle, Color.background, Color.accent, 0)
    border.width: DS.pick(w.deskStyle, "border", false) ? 1 : 0
    border.color: DS.border(w.deskStyle, Color.foreground)
  }

  // ---- one framed picture/video that fades (or slides) to the next file
  component Frame: ClippingRectangle {
    id: fr
    property var item: null
    property bool live: false                    // the middle one: plays videos, takes the effect
    property string effect: "fade"
    radius: w.rad
    color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.06)
    property var aItem: null
    property var bItem: null
    property bool aFront: true
    onItemChanged: { if (aFront) bItem = item; else aItem = item; aFront = !aFront }
    Component.onCompleted: { aItem = item; aFront = true }
    // ClippingRectangle moves its children into an inner item, so the
    // layers get the frame passed in rather than reading `parent`
    Layer { id: la; frame: fr; item: fr.aItem; front: fr.aFront }
    Layer { id: lb; frame: fr; item: fr.bItem; front: !fr.aFront }
  }
  component Layer: Item {
    id: ly
    property var item: null
    property bool front: false
    property var frame: null
    width: frame ? frame.width : 0; height: frame ? frame.height : 0
    z: front ? 1 : 0
    readonly property bool slide: !!frame && frame.live === true && frame.effect === "slide"
    opacity: slide ? 1 : (front ? 1 : 0)
    Behavior on opacity { NumberAnimation { duration: 700; easing.type: Easing.InOutQuad } }
    x: 0
    NumberAnimation { id: slideIn; target: ly; property: "x"; from: ly.width; to: 0; duration: 650; easing.type: Easing.OutCubic }
    NumberAnimation { id: slideOut; target: ly; property: "x"; from: 0; to: -ly.width; duration: 650; easing.type: Easing.OutCubic }
    onFrontChanged: {
      if (slide) { if (front) slideIn.restart(); else slideOut.restart() } else x = 0
      if (front && kenBurns) kb.restart()
    }
    // Ken Burns: a slow zoom and drift while it's on screen
    readonly property bool kenBurns: !!frame && frame.live === true && frame.effect === "kenburns"
    property real zoom: 1
    property real driftX: 0
    property real driftY: 0
    property int kbFlip: 0
    ParallelAnimation {
      id: kb
      readonly property int ms: (w.fd ? w.fd.interval : 10) * 1000 + 1500
      NumberAnimation { target: ly; property: "zoom"; from: 1.0; to: 1.14; duration: kb.ms; easing.type: Easing.InOutSine }
      NumberAnimation { target: ly; property: "driftX"; from: 0; to: (ly.kbFlip % 2 ? 1 : -1) * 0.04; duration: kb.ms; easing.type: Easing.InOutSine }
      NumberAnimation { target: ly; property: "driftY"; from: 0; to: (ly.kbFlip % 3 ? -1 : 1) * 0.03; duration: kb.ms; easing.type: Easing.InOutSine }
      onStarted: ly.kbFlip++
    }
    onKenBurnsChanged: if (!kenBurns) { kb.stop(); zoom = 1; driftX = 0; driftY = 0 } else if (front) kb.restart()
    Item {
      anchors.fill: parent
      scale: ly.zoom
      transform: Translate { x: ly.driftX * ly.width; y: ly.driftY * ly.height }
      Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        sourceSize.width: Math.round(ly.width * 1.5)
        source: ly.item && w.mod ? w.mod.url(w.mod.stillOf(ly.item)) : ""
      }
      Loader {
        anchors.fill: parent
        active: !!ly.item && ly.item.video === true && ly.front && !!ly.frame && ly.frame.live === true && !!w.fd && w.fd.on
        sourceComponent: Item {
          MediaPlayer {
            id: player
            source: w.mod.url(ly.item.path)
            loops: MediaPlayer.Infinite
            videoOutput: out
            onErrorOccurred: function(e, msg) { console.warn("gallery: video", msg, source) }
            Component.onCompleted: play()
          }
          VideoOutput { id: out; anchors.fill: parent; fillMode: VideoOutput.PreserveAspectCrop }
        }
      }
    }
  }

  // ---- the looks
  Item {
    id: stage
    x: w.pad; y: w.pad
    width: w.ww; height: w.hh

    // carousel sides: smaller, blurred, dimmed; click to step
    Frame {
      visible: w.carousel
      width: stage.width * 0.32; height: stage.height * 0.78
      anchors.verticalCenter: parent.verticalCenter
      x: 0
      item: w.fd ? w.fd.prevItem : null
      opacity: 0.75
      layer.enabled: true
      layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 40; saturation: -0.15; brightness: -0.12 }
      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: w.fd.step(-1) }
    }
    Frame {
      visible: w.carousel
      width: stage.width * 0.32; height: stage.height * 0.78
      anchors.verticalCenter: parent.verticalCenter
      x: stage.width - width
      item: w.fd ? w.fd.nextItem : null
      opacity: 0.75
      layer.enabled: true
      layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 40; saturation: -0.15; brightness: -0.12 }
      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: w.fd.step(1) }
    }
    // the middle one (carousel) or the only one (single)
    Frame {
      id: main
      z: 2
      live: true
      effect: w.carousel ? "fade" : (w.fd ? w.fd.effect : "fade")
      width: w.carousel ? stage.width * 0.58 : stage.width
      height: stage.height
      x: (stage.width - width) / 2
      item: w.fd ? w.fd.current : null
      layer.enabled: w.carousel
      layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 0.9; shadowOpacity: 0.5; shadowVerticalOffset: 3 }

      // "folder · date" when switched on, else the file's name while the pointer is over it
      Rectangle {
        z: 3
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: Style.space(30) * w.deskScale
        readonly property bool always: !!w.fd && w.fd.caption
        opacity: always || hover.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
        gradient: Gradient {
          GradientStop { position: 0; color: "transparent" }
          GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.55) }
        }
        Text {
          anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Style.space(8) * w.deskScale }
          elide: Text.ElideMiddle
          text: !w.fd || !w.fd.current ? "" : parent.always && !hover.containsMouse ? w.mod.captionOf(w.fd.current) : w.fd.current.path.split("/").pop()
          color: "white"; font.family: Fonts.ui; font.pixelSize: Style.font.caption * w.deskScale
        }
      }
      MouseArea {
        id: hover
        z: 4
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(m) { if (m.button === Qt.RightButton) w.fd.step(1); else w.mod.open(w.fd.current) }
        onWheel: function(e) { w.fd.step(e.angleDelta.y > 0 ? -1 : 1) }
      }
    }

    // nothing to show yet (the layout editor still shows the box)
    Text {
      z: 5
      visible: !w.fd || w.fd.count === 0
      anchors.centerIn: parent
      width: parent.width * 0.8; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
      text: w.mod ? w.mod.t("Галерея: в выбранных папках нет картинок", "Gallery: no pictures in the chosen folders") : ""
      color: Color.foreground; font.family: Fonts.ui; font.pixelSize: Style.font.body
    }
  }
}
