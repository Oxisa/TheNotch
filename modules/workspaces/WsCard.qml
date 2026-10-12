import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import "../../fonts"
import "../../vendor/soundhub" as SH

// One workspace in miniature: its windows where they really are, live
// (ScreencopyView). Click the card to go to the workspace, a window to
// focus it; drag a window onto another card to move it there.
Item {
  id: card
  property var mod: null
  property var ws: null
  property var monitor: null
  property bool live: true
  property bool big: false                      // the overview's own workspace: titles, close buttons
  property bool wallpaper: true                 // the wallpaper behind the windows
  property bool showLabel: !big
  signal picked()                               // a click went somewhere: the host may close
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property string ff: Fonts.ui
  // the monitor in layout (logical) units
  readonly property real monW: monitor ? monitor.width / (monitor.scale || 1) : 1920
  readonly property real monH: monitor ? monitor.height / (monitor.scale || 1) : 1080
  readonly property real k: width / monW
  height: Math.round(monH * k) + (showLabel ? label.height + Style.space(4) : 0)
  // while one of its windows is dragged the card sits above its neighbours
  property int dragging: 0
  z: dragging > 0 ? 10 : 0
  property bool dropping: drop.containsDrag

  Rectangle {
    id: screenRect
    width: card.width; height: Math.round(card.monH * card.k)
    radius: Style.space(big ? 14 : 8)
    color: SH.HubStyle.tint(card.fg, card.dropping ? 0.16 : 0.06)
    border.width: card.ws && card.ws.active ? 2 : card.dropping ? 2 : 1
    border.color: card.ws && card.ws.active || card.dropping ? card.accent : SH.HubStyle.tint(card.fg, 0.1)
    // the wallpaper behind, dimmed a little, so it reads as that screen
    ClippingRectangle {
      visible: card.wallpaper
      anchors.fill: parent; anchors.margins: parent.border.width
      radius: parent.radius
      color: "transparent"
      Image { anchors.fill: parent; source: card.wallpaper ? "file://" + Quickshell.env("HOME") + "/.local/state/omarchy/current/background" : ""; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 640; cache: true; opacity: 0.85 }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (card.ws) card.mod.goWorkspace(card.ws.id); card.picked() } }
    DropArea {
      id: drop
      anchors.fill: parent
      keys: ["thenotch-window"]
      onDropped: function(ev) { var tl = ev.source ? ev.source.tl : null; if (tl && card.ws && (!tl.workspace || tl.workspace.id !== card.ws.id)) card.mod.moveWindow(tl, card.ws.id) }
    }
    Repeater {
      model: card.mod ? card.mod.windowsOn(card.ws) : []
      delegate: Item {
        id: win
        required property var modelData
        readonly property var o: modelData.lastIpcObject || ({})
        readonly property var at: o.at || [0, 0]
        readonly property var sz: o.size || [0, 0]
        readonly property real mx: card.monitor ? card.monitor.x : 0
        readonly property real my: card.monitor ? card.monitor.y : 0
        visible: sz[0] > 0 && !o.hidden
        x: Math.max(0, (at[0] - mx) * card.k); y: Math.max(0, (at[1] - my) * card.k)
        width: Math.max(Style.space(16), sz[0] * card.k); height: Math.max(Style.space(12), sz[1] * card.k)
        z: o.floating ? 2 : 1
        ClippingRectangle {
          anchors.fill: parent
          radius: Style.space(card.big ? 10 : 5)
          color: SH.HubStyle.tint(card.fg, 0.12)
          border.width: winMouse.containsMouse ? 2 : 1; border.color: winMouse.containsMouse ? card.accent : Qt.rgba(0, 0, 0, 0.35)
          ScreencopyView {
            id: shot
            anchors.fill: parent
            captureSource: card.live && win.modelData.wayland ? win.modelData.wayland : null
            live: card.live
          }
          // the app's icon as a badge in the corner; centred only until the preview arrives
          IconImage {
            readonly property bool alone: !shot.hasContent
            anchors.centerIn: alone ? parent : undefined
            anchors.left: alone ? undefined : parent.left; anchors.bottom: alone ? undefined : parent.bottom
            anchors.margins: Style.space(card.big ? 8 : 3)
            width: alone ? Math.min(parent.width, parent.height) * 0.45 : Math.min(Style.space(card.big ? 32 : 14), parent.height * 0.4); height: width
            source: card.mod ? card.mod.iconOf(win.modelData) : ""
          }
        }
        Rectangle {                                   // the title, in the big view
          visible: card.big
          anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.bottom; anchors.topMargin: Style.space(6)
          width: Math.min(parent.width, tt.implicitWidth + Style.space(16)); height: Style.space(24); radius: height / 2
          color: Qt.rgba(0, 0, 0, 0.6)
          Text { id: tt; anchors.centerIn: parent; width: parent.width - Style.space(12); elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                 text: win.modelData.title || ""; color: "white"; font.family: card.ff; font.pixelSize: Style.font.caption }
        }
        Rectangle {                                   // pin over every workspace, in the big view
          visible: card.big && (winMouse.containsMouse || !!win.o.pinned)
          anchors.right: parent.right; anchors.top: parent.top; anchors.margins: Style.space(6); anchors.rightMargin: Style.space(36)
          width: Style.space(24); height: width; radius: width / 2; z: 3
          color: win.o.pinned ? card.accent : pinM.containsMouse ? SH.HubStyle.tint(card.accent, 0.6) : Qt.rgba(0, 0, 0, 0.6)
          Text { anchors.centerIn: parent; text: "\u{f0403}"; color: win.o.pinned ? Color.background : "white"; font.family: card.ff; font.pixelSize: Style.font.caption }
          MouseArea { id: pinM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: card.mod.pinWindow(win.modelData) }
        }
        Rectangle {                                   // close, in the big view
          visible: card.big && winMouse.containsMouse
          anchors.right: parent.right; anchors.top: parent.top; anchors.margins: Style.space(6)
          width: Style.space(24); height: width; radius: width / 2; z: 3
          color: closeM.containsMouse ? Color.urgent : Qt.rgba(0, 0, 0, 0.6)
          Text { anchors.centerIn: parent; text: "\u{f0156}"; color: "white"; font.family: card.ff; font.pixelSize: Style.font.caption }
          MouseArea { id: closeM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: card.mod.closeWindow(win.modelData) }
        }
        MouseArea {
          id: winMouse
          anchors.fill: parent
          hoverEnabled: true; cursorShape: Qt.PointingHandCursor
          drag.target: ghost
          drag.threshold: 6
          onClicked: { card.mod.goWindow(win.modelData); card.picked() }
          onReleased: if (ghost.Drag.active) ghost.Drag.drop()
        }
        // what moves while dragging: a lifted copy, back in place afterwards
        Rectangle {
          id: ghost
          readonly property var tl: win.modelData
          width: win.width; height: win.height
          radius: Style.space(6)
          color: SH.HubStyle.tint(card.accent, 0.35)
          border.width: 2; border.color: card.accent
          visible: Drag.active
          z: 100
          Drag.active: winMouse.drag.active
          Drag.onActiveChanged: card.dragging += Drag.active ? 1 : -1
          Drag.keys: ["thenotch-window"]
          Drag.hotSpot.x: width / 2; Drag.hotSpot.y: height / 2
          IconImage { anchors.centerIn: parent; width: Math.min(parent.width, parent.height) * 0.5; height: width; source: card.mod ? card.mod.iconOf(win.modelData) : "" }
          onVisibleChanged: if (!visible) { x = 0; y = 0 }
        }
      }
    }
  }
  Row {
    id: label
    visible: card.showLabel
    anchors.top: screenRect.bottom; anchors.topMargin: Style.space(4)
    spacing: Style.space(6)
    Text { text: card.ws ? String(card.ws.id) : ""; color: card.ws && card.ws.active ? card.accent : card.fg; font.family: card.ff; font.pixelSize: Style.font.caption; font.bold: true }
    Text { text: card.ws && card.mod ? card.mod.nameOf(card.ws) : ""; color: Qt.darker(card.fg, 1.3); font.family: card.ff; font.pixelSize: Style.font.caption }
    Text {
      visible: !!(card.ws && card.mod && card.mod.layoutOf(card.ws.id))
      text: card.ws && card.mod ? "· " + card.mod.layoutOf(card.ws.id) : ""
      color: Qt.darker(card.fg, 1.6); font.family: card.ff; font.pixelSize: Style.font.caption - 1
    }
  }
}
