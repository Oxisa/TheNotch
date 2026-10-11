import QtQuick
import Quickshell
import Quickshell.Wayland

// One desktop widget on one monitor, at its place from the layout: a small
// layer window under the windows (WlrLayer.Bottom) sized to the widget's
// bounding box (it may be rotated). Only the widget takes clicks, and only
// while it's shown.
PanelWindow {
  id: win
  property var notch: null
  property var desk: null                    // { wid, component, … } from notch.deskItems
  property real posX: 0
  property real posY: 0
  property real rot: 0
  property real savedW: 0                    // its box when it was placed (for auto-alignment)
  property real savedH: 0
  property real sc: 1                        // the widget's scale from the layout

  property bool canVertical: false             // set once the content loads
  readonly property var turn: notch ? notch.turnOf(rot, canVertical) : { vertical: false, rot: rot }
  readonly property real cw: content.item ? content.item.width * sc : 1
  readonly property real ch: content.item ? content.item.height * sc : 1
  readonly property real rad: turn.rot * Math.PI / 180
  readonly property real bw: Math.abs(cw * Math.cos(rad)) + Math.abs(ch * Math.sin(rad))
  readonly property real bh: Math.abs(cw * Math.sin(rad)) + Math.abs(ch * Math.cos(rad))

  color: "transparent"
  WlrLayershell.namespace: "osia-thenotch-widget"
  WlrLayershell.layer: WlrLayer.Bottom
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  anchors { top: true; left: true }
  readonly property var at: notch && screen ? notch.anchored({ x: posX, y: posY, w: savedW, h: savedH }, bw, bh, screen.width, screen.height)
                                            : { x: posX, y: posY }
  margins { top: win.at.y; left: win.at.x }
  implicitWidth: Math.max(1, Math.ceil(bw))
  implicitHeight: Math.max(1, Math.ceil(bh))

  readonly property bool shown: content.item ? content.item.deskShown !== false : false
  Region { id: all; item: box }
  Region { id: none }
  mask: shown ? all : none

  Item {
    id: box
    anchors.fill: parent
    Loader {
      id: content
      anchors.centerIn: parent
      rotation: win.turn.rot
      scale: win.sc
      sourceComponent: win.desk ? win.desk.component : null
      opacity: win.shown ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 300 } }
      onLoaded: { win.canVertical = "deskVertical" in item; win.feed(); adopt.restart() }
    }
  }
  // where it sits, for widgets that adapt (the clock turns its rings toward the middle)
  function feed() {
    var it = content.item, sc = win.screen
    if (!it || !sc) return
    if ("screenW" in it) it.screenW = sc.width
    if ("screenH" in it) it.screenH = sc.height
    if ("fx" in it) it.fx = (at.x + bw / 2) / sc.width
    if ("fy" in it) it.fy = (at.y + bh / 2) / sc.height
    if ("editing" in it) it.editing = false
    if ("deskVertical" in it) it.deskVertical = turn.vertical
  }
  onTurnChanged: feed()
  // older layouts saved no size: record it once, so auto-alignment knows the box
  property string wid: desk ? desk.wid : ""
  Timer {
    id: adopt
    interval: 1500
    onTriggered: if (win.savedW <= 0 && win.notch && win.screen && win.bw > 1 && win.wid)
      win.notch.patchPlace(win.wid, String(win.screen.name), { w: Math.round(win.bw), h: Math.round(win.bh) })
  }
  onPosXChanged: feed()
  onPosYChanged: feed()
}
