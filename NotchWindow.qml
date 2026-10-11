import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons

// The notch itself, on one edge of one monitor. A strip-shaped layer window
// along the edge; only the island takes input (mask), the rest is
// click-through. The island grows and morphs between the core's modes:
//   idle      ears: workspace · clock
//   live      the live module's ears (e.g. cover · spectrum)
//   event     icon/art + title + message or a progress bar
//   peek      the live module's hover card
//   expanded  module icons on top, the current module's dashboard below
// Top/bottom edges lay the collapsed ears out in a row, left/right in a column.
PanelWindow {
  id: win
  property var notch: null
  property string edge: "top"

  readonly property bool vertical: edge === "left" || edge === "right"
  readonly property string mode: notch ? notch.mode : "idle"
  readonly property color fill: notch ? notch.islandColor : "black"
  readonly property color fg: notch ? notch.fg : "white"
  readonly property color accent: notch ? notch.accent : "white"
  readonly property string ff: notch ? notch.ff : ""
  readonly property real pad: Style.space(14)
  readonly property real thin: Style.space(32)          // collapsed thickness
  // limits come from the screen, not this window (whose size follows the island)
  readonly property real screenW: screen ? screen.width : 1920
  readonly property real screenH: screen ? screen.height : 1080
  readonly property real maxW: screenW - Style.space(40)
  readonly property real maxH: screenH - Style.space(40)

  color: "transparent"
  WlrLayershell.namespace: "osia-thenotch"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: win.mode === "expanded" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  // windows keep clear of the collapsed notch, like they did of the bar
  exclusionMode: notch && notch.opt("reserve", true) === true ? ExclusionMode.Normal : ExclusionMode.Ignore
  exclusiveZone: notch && notch.opt("reserve", true) === true ? Math.round(thin) : 0
  anchors {
    top: edge !== "bottom"
    bottom: edge !== "top"
    left: edge !== "right"
    right: edge !== "left"
  }
  // deep enough for the biggest state; the island animates inside
  implicitHeight: vertical ? 0 : Math.max(island.height, island.targetH) + Style.space(24)
  implicitWidth: vertical ? Math.max(island.width, island.targetW) + Style.space(24) : 0
  mask: Region { item: island }

  // -------------------------------------------------------- target sizes
  readonly property var cur: notch ? notch.current : null
  readonly property var live: notch ? notch.liveModule : null
  property real pageW: cur ? Style.space(cur.pageWidth) : Style.space(440)
  property real pageH: expandedPage.item ? expandedPage.item.implicitHeight : Style.space(200)
  readonly property real railH: Style.space(62)

  function sizeFor(m) {
    if (m === "expanded") {
      return { w: Math.min(maxW, pageW + pad * 2), h: Math.min(maxH, railH + pageH + pad * 2 + Style.space(8)) }
    }
    if (m === "peek") {
      var pw = live && live.peekWidth ? Style.space(live.peekWidth) : Style.space(380)
      var ph = peekLoader.item ? peekLoader.item.implicitHeight : Style.space(100)
      return { w: pw + pad * 2, h: ph + pad * 2 }
    }
    if (m === "event") {
      var big = notch && notch.currentEvent && notch.currentEvent.big
      return big ? { w: Style.space(400), h: Style.space(78) } : { w: Style.space(320), h: Style.space(56) }
    }
    if (m === "live") return vertical ? { w: thin + Style.space(4), h: Style.space(190) } : { w: Style.space(280), h: thin + Style.space(2) }
    return vertical ? { w: thin, h: Style.space(earExtra ? 210 : 150) } : { w: Style.space(earExtra ? 270 : 200), h: thin }
  }
  // anything a module wants next to the clock (weather); widens the idle notch
  readonly property string earExtra: {
    var ms = notch ? notch.modules : []
    var out = []
    for (var i = 0; i < ms.length; i++) if (ms[i].active && ms[i].ear) out.push(ms[i].ear)
    return out.join("   ")
  }
  readonly property var target: sizeFor(mode)
  readonly property bool big: mode === "expanded" || mode === "peek"
  readonly property real radius: big ? Style.space(22) : mode === "event" ? Style.space(20) : thin / 2

  // Safety net for a missed pointer-leave (it happens while the island is
  // resizing under the cursor): while the notch is open, ask Hyprland where
  // the cursor is and close if it's clearly off the island.
  readonly property bool open: mode === "expanded" || mode === "peek"
  Timer {
    interval: 400; repeat: true
    running: win.open
    onTriggered: if (!cursorProc.running) cursorProc.running = true
  }
  Process {
    id: cursorProc
    command: ["hyprctl", "cursorpos", "-j"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var c = JSON.parse(text), scr = win.screen
          if (!scr) return
          // the window hugs its edge of the screen
          var wx = scr.x + (win.edge === "right" ? scr.width - win.width : 0)
          var wy = scr.y + (win.edge === "bottom" ? scr.height - win.height : 0)
          var m = Style.space(16)                     // slack for dropdowns at the rim
          var inside = c.x >= wx + island.x - m && c.x <= wx + island.x + island.width + m
                    && c.y >= wy + island.y - m && c.y <= wy + island.y + island.height + m
          if (inside && !win.notch.pointerInside) win.notch.setPointerInside(true)
          else if (!inside && win.notch.visited) win.notch.setPointerInside(false)
        } catch (e) {}
      }
    }
  }

  // ---------------------------------------------------------------- island
  Item {
    id: island
    readonly property real targetW: win.target.w
    readonly property real targetH: win.target.h
    width: targetW
    height: targetH
    Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

    x: win.edge === "left" ? 0 : win.edge === "right" ? win.width - width : Math.round((win.width - width) / 2)
    y: win.edge === "top" ? 0 : win.edge === "bottom" ? win.height - height : Math.round((win.height - height) / 2)

    Rectangle {
      id: shape
      anchors.fill: parent
      color: win.fill
      // flat on the screen edge, round elsewhere
      topLeftRadius: win.edge === "top" || win.edge === "left" ? 0 : win.radius
      topRightRadius: win.edge === "top" || win.edge === "right" ? 0 : win.radius
      bottomLeftRadius: win.edge === "bottom" || win.edge === "left" ? 0 : win.radius
      bottomRightRadius: win.edge === "bottom" || win.edge === "right" ? 0 : win.radius
      Behavior on topLeftRadius { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
      Behavior on topRightRadius { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
      Behavior on bottomLeftRadius { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
      Behavior on bottomRightRadius { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
      // no outline: it ran along the screen edge and stopped at the concave
      // corners, so the notch looked pieced together
    }
    // concave corners where the island meets a top/bottom edge
    Fillet { visible: !win.vertical; flip: win.edge === "bottom"; fill: win.fill; x: -width; y: win.edge === "top" ? 0 : parent.height - height }
    Fillet { visible: !win.vertical; flip: win.edge === "bottom"; mirrored: true; fill: win.fill; x: parent.width; y: win.edge === "top" ? 0 : parent.height - height }

    // click opens/closes; controls inside take their own clicks first
    MouseArea {
      anchors.fill: parent
      onClicked: win.mode === "event" ? win.notch.clickEvent() : win.notch.expand()
    }
    HoverHandler { onHoveredChanged: win.notch.setPointerInside(hovered) }

    // -------------------------------------------------- collapsed: ears
    Item {
      id: ears
      anchors.fill: parent
      anchors.leftMargin: win.vertical ? 0 : Style.space(14)
      anchors.rightMargin: win.vertical ? 0 : Style.space(14)
      anchors.topMargin: win.vertical ? Style.space(12) : 0
      anchors.bottomMargin: win.vertical ? Style.space(12) : 0
      opacity: win.mode === "idle" || win.mode === "live" ? 1 : 0
      visible: opacity > 0
      Behavior on opacity { NumberAnimation { duration: 180 } }

      readonly property bool isLive: win.mode === "live" && win.live !== null
      readonly property string ws: Hyprland.focusedWorkspace ? String(Hyprland.focusedWorkspace.id) : ""
      property date now: new Date()
      Timer { interval: 1000; running: ears.visible; repeat: true; triggeredOnStart: true; onTriggered: ears.now = new Date() }
      readonly property string hh: Qt.formatTime(now, "HH")
      readonly property string mm: Qt.formatTime(now, "mm")

      component Ws: Rectangle {
        width: Math.max(height, wsText.implicitWidth + Style.space(12)); height: Style.space(20)
        radius: height / 2
        color: Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.22)
        Text {
          id: wsText
          anchors.centerIn: parent
          text: ears.ws
          color: win.accent
          font.family: win.ff; font.pixelSize: Style.font.caption; font.bold: true
        }
      }

      // left / top ear
      Loader {
        id: earA
        anchors.left: win.vertical ? undefined : parent.left
        anchors.verticalCenter: win.vertical ? undefined : parent.verticalCenter
        anchors.top: win.vertical ? parent.top : undefined
        anchors.horizontalCenter: win.vertical ? parent.horizontalCenter : undefined
        sourceComponent: ears.isLive && win.live.liveLeft ? win.live.liveLeft : wsComp
      }
      // right / bottom ear
      Loader {
        id: earB
        anchors.right: win.vertical ? undefined : parent.right
        anchors.verticalCenter: win.vertical ? undefined : parent.verticalCenter
        anchors.bottom: win.vertical ? parent.bottom : undefined
        anchors.horizontalCenter: win.vertical ? parent.horizontalCenter : undefined
        sourceComponent: ears.isLive && win.live.liveRight ? win.live.liveRight : clockComp
      }
      Component { id: wsComp; Ws {} }
      readonly property string extra: win.earExtra
      Component {
        id: clockComp
        Text {
          text: win.vertical ? (ears.extra ? ears.extra.replace(" ", "\n") + "\n" : "") + ears.hh + "\n" + ears.mm
                             : (ears.extra ? ears.extra + "   " : "") + ears.hh + ":" + ears.mm
          horizontalAlignment: Text.AlignHCenter
          lineHeight: 0.9
          color: win.fg
          font.family: win.ff; font.pixelSize: Style.font.body; font.bold: true
        }
      }
    }

    // ---------------------------------------------------------- event
    Item {
      id: eventView
      anchors.fill: parent
      anchors.margins: Style.space(10)
      opacity: win.mode === "event" ? 1 : 0
      visible: opacity > 0
      Behavior on opacity { NumberAnimation { duration: 180 } }
      readonly property var ev: win.notch ? win.notch.currentEvent : null

      Rectangle {                                    // × for events that can be dismissed
        id: closeBtn
        visible: !!(eventView.ev && typeof eventView.ev.dismiss === "function")
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(24); height: width; radius: width / 2
        z: 2
        color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, closeMouse.containsMouse ? 0.16 : 0.07)
        Text { anchors.centerIn: parent; text: "󰅖"; color: win.fg; font.family: win.ff; font.pixelSize: Style.font.caption }
        MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.notch.dismissEvent() }
      }

      Row {
        anchors.fill: parent
        anchors.leftMargin: Style.space(6)
        spacing: Style.space(12)
        Item {
          width: Style.space(36); height: width
          anchors.verticalCenter: parent.verticalCenter
          Image {
            id: evArt
            anchors.fill: parent
            visible: !!(eventView.ev && eventView.ev.art)
            source: eventView.ev && eventView.ev.art ? eventView.ev.art : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(72, 72)
          }
          Image {
            id: evIcon
            anchors.fill: parent
            anchors.margins: Style.space(2)
            visible: !evArt.visible && !!(eventView.ev && eventView.ev.iconSource) && status === Image.Ready
            source: eventView.ev && eventView.ev.iconSource ? eventView.ev.iconSource : ""
            fillMode: Image.PreserveAspectFit
            sourceSize: Qt.size(72, 72)
          }
          Text {
            anchors.centerIn: parent
            visible: !evArt.visible && !evIcon.visible
            text: eventView.ev ? (eventView.ev.icon || "󰋼") : ""
            color: win.accent
            font.family: win.ff; font.pixelSize: Style.space(22)
          }
        }
        Column {
          width: parent.width - Style.space(48) - parent.spacing - (closeBtn.visible ? closeBtn.width + Style.space(6) : 0)
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(5)
          Text {
            width: parent.width
            text: eventView.ev ? (eventView.ev.title || "") : ""
            color: win.fg
            font.family: win.ff; font.pixelSize: Style.font.body; font.bold: true
            elide: Text.ElideRight
          }
          Text {
            width: parent.width
            visible: !!(eventView.ev && eventView.ev.message) && !(eventView.ev.progress >= 0)
            text: eventView.ev ? (eventView.ev.message || "") : ""
            color: Qt.darker(win.fg, 1.4)
            font.family: win.ff; font.pixelSize: Style.font.caption
            wrapMode: Text.Wrap
            maximumLineCount: eventView.ev && eventView.ev.big ? 2 : 1
            elide: Text.ElideRight
          }
          Rectangle {
            visible: !!eventView.ev && eventView.ev.progress >= 0
            width: parent.width - Style.space(6); height: Style.space(5); radius: height / 2
            color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, 0.15)
            Rectangle {
              width: parent.width * (eventView.ev && eventView.ev.progress >= 0 ? eventView.ev.progress : 0)
              height: parent.height; radius: height / 2
              color: win.accent
              Behavior on width { NumberAnimation { duration: 120 } }
            }
          }
        }
      }
    }

    // ----------------------------------------------------------- peek
    Loader {
      id: peekLoader
      x: win.pad; y: win.pad
      width: island.width - win.pad * 2
      active: win.live !== null && win.live.peek !== null
      sourceComponent: win.live ? win.live.peek : null
      opacity: win.mode === "peek" ? 1 : 0
      visible: opacity > 0
      Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    // ------------------------------------------------------- expanded
    Item {
      id: expanded
      anchors.fill: parent
      anchors.margins: win.pad
      opacity: win.mode === "expanded" ? 1 : 0
      visible: opacity > 0
      Behavior on opacity { NumberAnimation { duration: 220 } }
      focus: win.mode === "expanded"
      Keys.onEscapePressed: win.notch.expanded = false

      // tabs across the width, icon over label, with a sliding underline
      // (after caelestia); the other dashboards are small icons on the
      // right; a dashboard opened by its icon shows "‹ <last tab>" instead
      readonly property bool onTab: win.cur !== null && win.cur.topTab
      Row {
        id: rail
        visible: expanded.onTab
        width: icons.x - Style.space(12)
        height: win.railH - Style.space(10)
        Repeater {
          id: tabs
          model: win.notch ? win.notch.tabModules : []
          delegate: Item {
            id: tabBtn
            required property var modelData
            readonly property bool on: win.cur === modelData
            height: rail.height
            width: rail.width / Math.max(1, tabs.count)
            Column {
              id: tabCol
              anchors.centerIn: parent
              spacing: Style.space(2)
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: tabBtn.modelData.icon
                color: tabBtn.on ? win.accent : Qt.darker(win.fg, tabMouse.containsMouse ? 1.1 : 1.45)
                font.family: win.ff; font.pixelSize: Style.font.body + 3
              }
              Text {
                id: tabLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: tabBtn.modelData.title
                color: tabBtn.on ? win.accent : Qt.darker(win.fg, tabMouse.containsMouse ? 1.1 : 1.45)
                font.family: win.ff; font.pixelSize: Style.font.caption + 1; font.bold: tabBtn.on
              }
            }
            readonly property real lineW: tabLabel.implicitWidth + Style.space(16)
            MouseArea {
              id: tabMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: win.notch.openModule(tabBtn.modelData.moduleId)
            }
          }
        }
      }
      Rectangle {                                        // the underline under the current tab
        id: underline
        visible: expanded.onTab
        readonly property var target: {
          for (var i = 0; i < tabs.count; i++) { var it = tabs.itemAt(i); if (it && it.on) return it }
          return null
        }
        x: target ? rail.x + target.x + (target.width - target.lineW) / 2 : 0
        width: target ? target.lineW : 0
        y: rail.height + Style.space(1)
        height: 3; radius: 1.5
        color: win.accent
        Behavior on x { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
      }
      Rectangle {                                        // a thin line under the whole row
        y: rail.height + Style.space(3)
        width: parent.width; height: 1
        color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, 0.08)
      }
      // back to the last tab from a module's page
      Rectangle {
        id: back
        visible: !expanded.onTab
        anchors.verticalCenter: icons.verticalCenter
        height: Style.space(30)
        width: backRow.implicitWidth + Style.space(20)
        radius: height / 2
        color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, backMouse.containsMouse ? 0.12 : 0.06)
        readonly property var to: win.notch ? win.notch.moduleById(win.notch.lastTab) : null
        Row {
          id: backRow
          anchors.centerIn: parent
          spacing: Style.space(6)
          Text { anchors.verticalCenter: parent.verticalCenter; text: "\u{f0141}"; color: win.fg; font.family: win.ff; font.pixelSize: Style.font.body + 1 }
          Text { anchors.verticalCenter: parent.verticalCenter; text: back.to ? back.to.title : ""; color: win.fg; font.family: win.ff; font.pixelSize: Style.font.body }
        }
        MouseArea {
          id: backMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: win.notch.openModule(win.notch.lastTab)
        }
      }
      // the other dashboards: small icons before the gear
      Row {
        id: icons
        anchors.right: gear.left; anchors.rightMargin: Style.space(8)
        y: (rail.height - height) / 2
        spacing: Style.space(4)
        Repeater {
          model: win.notch ? win.notch.iconModules : []
          delegate: Rectangle {
            id: ib
            required property var modelData
            readonly property bool on: win.cur === modelData
            width: Style.space(30); height: width; radius: width / 2
            color: on ? win.accent : Qt.rgba(win.fg.r, win.fg.g, win.fg.b, ibMouse.containsMouse ? 0.12 : 0.05)
            Text { anchors.centerIn: parent; text: ib.modelData.icon; color: ib.on ? win.fill : win.fg; font.family: win.ff; font.pixelSize: Style.font.body }
            MouseArea { id: ibMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.notch.openModule(ib.modelData.moduleId) }
          }
        }
      }
      // gear: the settings window (sections for every module)
      Rectangle {
        id: gear
        anchors.right: parent.right
        y: (rail.height - height) / 2
        height: Style.space(30); width: height; radius: height / 2
        color: Qt.rgba(win.fg.r, win.fg.g, win.fg.b, gearMouse.containsMouse ? 0.12 : 0.06)
        Behavior on color { ColorAnimation { duration: 160 } }
        Text {
          anchors.centerIn: parent
          text: "󰒓"
          color: win.fg
          rotation: gearMouse.containsMouse ? 60 : 0
          Behavior on rotation { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
          font.family: win.ff; font.pixelSize: Style.font.body + 1
        }
        MouseArea {
          id: gearMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: win.notch.openSettings(win.cur ? win.cur.moduleId : "settings")
        }
      }
      Text {
        visible: !expanded.onTab
        anchors.left: back.right; anchors.leftMargin: Style.space(12)
        anchors.right: gear.left; anchors.rightMargin: Style.space(8)
        elide: Text.ElideRight
        anchors.verticalCenter: back.verticalCenter
        text: win.cur ? (win.cur.icon + "  " + win.cur.title) : ""
        color: Qt.darker(win.fg, 1.3)
        font.family: win.ff; font.pixelSize: Style.font.body; font.bold: true
      }

      Flickable {
        id: pageArea
        y: win.railH
        width: parent.width
        height: parent.height - win.railH
        contentHeight: expandedPage.item ? expandedPage.item.implicitHeight : 0
        clip: true
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        Loader {
          id: expandedPage
          width: pageArea.width
          // built on first open, then kept; switching modules rebuilds
          property bool everOpened: false
          active: everOpened
          sourceComponent: win.cur ? win.cur.page : null
        }
      }
      Connections {
        target: win
        function onModeChanged() { if (win.mode === "expanded") expandedPage.everOpened = true }
      }
    }
  }
}
