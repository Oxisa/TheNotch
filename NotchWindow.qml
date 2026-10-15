import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
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
  // The window grows at once and shrinks only after the island has: resizing
  // a layer surface on every animation frame made the animation stutter.
  property real keepW: 0
  property real keepH: 0
  readonly property real wantW: island.targetW
  readonly property real wantH: island.targetH
  onWantWChanged: { if (wantW >= keepW) keepW = wantW; else shrinkLater.restart() }
  onWantHChanged: { if (wantH >= keepH) keepH = wantH; else shrinkLater.restart() }
  Timer { id: shrinkLater; interval: 380; onTriggered: { win.keepW = win.wantW; win.keepH = win.wantH } }
  implicitHeight: vertical ? 0 : Math.max(keepH, wantH) + Style.space(24)
  implicitWidth: vertical ? Math.max(keepW, wantW) + Style.space(24) : 0
  mask: Region { item: island }

  // -------------------------------------------------------- target sizes
  readonly property var cur: notch ? notch.current : null
  readonly property var live: notch ? notch.liveModule : null
  readonly property var peekMod: notch ? notch.peekModule : null
  // the mic / camera dots (Privacy) take this much room at the far end
  readonly property bool priv: notch !== null && notch.privacyShown
  property real pageW: cur ? Style.space(cur.pageWidth) : Style.space(440)
  property real pageH: expandedPage.item ? expandedPage.item.implicitHeight : Style.space(200)
  readonly property real railH: Style.space(62)

  function sizeFor(m) {
    if (notch && notch.dropHover && m !== "expanded") return vertical ? { w: Style.space(120), h: Style.space(240) } : { w: Style.space(340), h: Style.space(60) }
    if (m === "expanded") {
      return { w: Math.min(maxW, pageW + pad * 2), h: Math.min(maxH, railH + pageH + pad * 2 + Style.space(8)) }
    }
    if (m === "peek") {
      var pw = peekMod && peekMod.peekWidth ? Style.space(peekMod.peekWidth) : Style.space(380)
      var ph = peekLoader.item ? peekLoader.item.implicitHeight : Style.space(100)
      return { w: pw + pad * 2, h: ph + pad * 2 }
    }
    if (m === "event") {
      var big = notch && notch.currentEvent && notch.currentEvent.big
      return big ? { w: Style.space(400), h: Style.space(78) } : { w: Style.space(320), h: Style.space(56) }
    }
    // collapsed: as wide as the two sides need, kept symmetric around the middle
    var a = vertical ? sideA.implicitHeight : sideA.implicitWidth, b = vertical ? sideB.implicitHeight : sideB.implicitWidth
    var len = Math.max(Style.space(m === "live" ? 260 : 190), 2 * Math.max(a, b) + Style.space(28) + Style.space(40))
    return vertical ? { w: thin + (m === "live" ? Style.space(4) : 0), h: len } : { w: len, h: thin + (m === "live" ? Style.space(2) : 0) }
  }
  readonly property var target: sizeFor(mode)
  readonly property bool big: mode === "expanded" || mode === "peek"
  readonly property real radius: big ? Style.space(22) : mode === "event" ? Style.space(20) : thin / 2

  // Safety net for a missed pointer-leave (it happens while the island is
  // resizing under the cursor): while the notch is open, ask Hyprland where
  // the cursor is and close if it's clearly off the island.
  readonly property bool open: mode === "expanded" || mode === "peek"
  Timer {
    interval: 1000; repeat: true
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

    // The island as ONE shape with its concave corners (top / bottom edge):
    // separate pieces left a hairline seam at fractional scales, and it
    // flickered while the width animated.
    readonly property real rad: win.radius
    property real r: rad
    Behavior on r { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
    readonly property real f: Style.space(12)                  // the concave corner's size
    readonly property real cr: Math.max(0, Math.min(r, height / 2, width / 2))
    Shape {
      id: shape
      visible: !win.vertical
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer
      // drawn for the top edge; turned over for the bottom one
      transform: Scale { origin.y: shape.height / 2; yScale: win.edge === "bottom" ? -1 : 1 }
      ShapePath {
        fillColor: win.fill
        strokeWidth: -1
        startX: -island.f; startY: 0
        PathArc { x: 0; y: island.f; radiusX: island.f; radiusY: island.f; direction: PathArc.Clockwise }
        PathLine { x: 0; y: shape.height - island.cr }
        PathArc { x: island.cr; y: shape.height; radiusX: island.cr; radiusY: island.cr; direction: PathArc.Counterclockwise }
        PathLine { x: shape.width - island.cr; y: shape.height }
        PathArc { x: shape.width; y: shape.height - island.cr; radiusX: island.cr; radiusY: island.cr; direction: PathArc.Counterclockwise }
        PathLine { x: shape.width; y: island.f }
        PathArc { x: shape.width + island.f; y: 0; radiusX: island.f; radiusY: island.f; direction: PathArc.Clockwise }
        PathLine { x: -island.f; y: 0 }
      }
    }
    // the same shape turned on its side: drawn for the left edge, mirrored
    // for the right one
    Shape {
      id: sideShape
      visible: win.vertical
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer
      transform: Scale { origin.x: sideShape.width / 2; xScale: win.edge === "right" ? -1 : 1 }
      ShapePath {
        fillColor: win.fill
        strokeWidth: -1
        startX: 0; startY: -island.f
        PathArc { x: island.f; y: 0; radiusX: island.f; radiusY: island.f; direction: PathArc.Counterclockwise }
        PathLine { x: sideShape.width - island.cr; y: 0 }
        PathArc { x: sideShape.width; y: island.cr; radiusX: island.cr; radiusY: island.cr; direction: PathArc.Clockwise }
        PathLine { x: sideShape.width; y: sideShape.height - island.cr }
        PathArc { x: sideShape.width - island.cr; y: sideShape.height; radiusX: island.cr; radiusY: island.cr; direction: PathArc.Clockwise }
        PathLine { x: island.f; y: sideShape.height }
        PathArc { x: 0; y: sideShape.height + island.f; radiusX: island.f; radiusY: island.f; direction: PathArc.Counterclockwise }
        PathLine { x: 0; y: -island.f }
      }
    }

    // click opens/closes; controls inside take their own clicks first;
    // middle click: the microphone on / off, whatever the notch shows
    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.MiddleButton
      onClicked: function(mouse) {
        if (mouse.button === Qt.MiddleButton) win.notch.toggleMic()
        else if (win.mode === "event") win.notch.clickEvent()
        else win.notch.expand()
      }
    }
    HoverHandler { onHoveredChanged: win.notch.setPointerInside(hovered) }

    // -------------------------------------------------- collapsed: ears
    // Two sides, each a list of items from Settings → Personalisation →
    // Notch (Service.slots). Something live (music, a download, a timer)
    // takes a side over; the mic/camera dots and "mic off" stay.
    Item {
      id: ears
      anchors.fill: parent
      anchors.leftMargin: win.vertical ? 0 : Style.space(14)
      anchors.rightMargin: win.vertical ? 0 : Style.space(14)
      anchors.topMargin: win.vertical ? Style.space(12) : 0
      anchors.bottomMargin: win.vertical ? Style.space(12) : 0
      opacity: (win.mode === "idle" || win.mode === "live") && !(win.notch && win.notch.dropHover) ? 1 : 0
      visible: opacity > 0
      Behavior on opacity { NumberAnimation { duration: 180 } }

      readonly property bool isLive: win.mode === "live" && win.live !== null
      readonly property var ws: Hyprland.focusedWorkspace
      property date now: new Date()
      Timer { interval: 1000; running: ears.visible; repeat: true; triggeredOnStart: true; onTriggered: ears.now = new Date() }
      readonly property string hh: Qt.formatTime(now, "HH")
      readonly property string mm: Qt.formatTime(now, "mm")
      readonly property var wsMod: win.notch ? win.notch.moduleById("workspaces") : null
      readonly property var weatherMod: win.notch ? win.notch.moduleById("weather") : null
      readonly property bool micOff: win.notch !== null && win.notch.micMuted

      // something live (music, a download) joins a side on the inner end,
      // next to the middle; your own items stay
      function itemsFor(side) {
        var list = win.notch ? (win.notch.slots[side] || []) : []
        var live = side === "left" ? (isLive && win.live.liveLeft) : (isLive && win.live.liveRight)
        if (!live) return list
        return side === "left" ? list.concat(["live"]) : ["live"].concat(list)
      }
      function compFor(key, side) {
        if (key === "live") return side === "left" ? win.live.liveLeft : win.live.liveRight
        return { workspace: wsComp, apps: appsComp, shelf: shelfComp, clock: clockComp, weather: weatherComp, layout: layoutComp, privacy: privacyComp, mic: micComp }[key] || null
      }
      readonly property var shelfMod: win.notch ? win.notch.moduleById("shelf") : null

      component Side: Grid {
        id: side
        property string which: "left"
        // only one of rows/columns: with both set, Grid adds spacing for every
        // empty row too, and a vertical side grew into a strip down the screen
        rows: win.vertical ? -1 : 1
        columns: win.vertical ? 1 : -1
        spacing: Style.space(8)
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter
        Repeater {
          model: ears.itemsFor(side.which)
          delegate: Loader {
            required property string modelData
            sourceComponent: ears.compFor(modelData, side.which)
            // an item hides itself with `shown: false` (its own `visible` would follow the Loader's)
            visible: item !== null && item.shown !== false
          }
        }
      }
      Side {
        id: sideA
        which: "left"
        anchors.left: win.vertical ? undefined : parent.left
        anchors.verticalCenter: win.vertical ? undefined : parent.verticalCenter
        anchors.top: win.vertical ? parent.top : undefined
        anchors.horizontalCenter: win.vertical ? parent.horizontalCenter : undefined
      }
      Side {
        id: sideB
        which: "right"
        anchors.right: win.vertical ? undefined : parent.right
        anchors.verticalCenter: win.vertical ? undefined : parent.verticalCenter
        anchors.bottom: win.vertical ? parent.bottom : undefined
        anchors.horizontalCenter: win.vertical ? parent.horizontalCenter : undefined
      }

      // ---- the items
      Component {
        id: wsComp
        Rectangle {
          readonly property string name: ears.wsMod && ears.ws ? ears.wsMod.nameOf(ears.ws) : ""
          width: Math.max(height, wsText.implicitWidth + Style.space(12)); height: Style.space(20)
          radius: height / 2
          color: Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.22)
          Text {
            id: wsText
            anchors.centerIn: parent
            text: ears.ws ? String(ears.ws.id) + (parent.name && !win.vertical ? " " + parent.name : "") : ""
            color: win.accent
            font.family: win.ff; font.pixelSize: Style.font.caption; font.bold: true
          }
          // the wheel walks the workspaces; a click opens the overview
          WheelHandler { onWheel: function(ev) { Hyprland.dispatch('hl.dsp.focus({ workspace = "' + (ev.angleDelta.y < 0 ? "e+1" : "e-1") + '" })') } }
          TapHandler { onTapped: Quickshell.execDetached(["omarchy-shell", "osia.thenotch", "overview"]) }
        }
      }
      Component {
        id: appsComp
        Grid {
          rows: win.vertical ? 4 : 1; columns: win.vertical ? 1 : 4
          spacing: Style.space(4)
          readonly property bool shown: !!(ears.ws && ears.ws.toplevels && ears.ws.toplevels.values.length)
          Repeater {
            id: apps
            model: ears.ws && ears.ws.toplevels ? ears.ws.toplevels.values.slice(0, 4) : []
            delegate: IconImage {
              required property var modelData
              width: Style.space(16); height: width
              source: ears.wsMod ? ears.wsMod.iconOf(modelData) : ""
            }
          }
        }
      }
      Component {
        id: clockComp
        Text {
          text: win.vertical ? ears.hh + "\n" + ears.mm : ears.hh + ":" + ears.mm
          horizontalAlignment: Text.AlignHCenter
          lineHeight: 0.9
          color: win.fg
          font.family: win.ff; font.pixelSize: Style.font.body; font.bold: true
        }
      }
      Component {
        id: weatherComp
        Text {
          readonly property bool shown: !!(ears.weatherMod && ears.weatherMod.active && ears.weatherMod.ear)
          text: ears.weatherMod ? (win.vertical ? String(ears.weatherMod.ear).replace(" ", "\n") : ears.weatherMod.ear) : ""
          horizontalAlignment: Text.AlignHCenter
          color: win.fg
          font.family: win.ff; font.pixelSize: Style.font.body; font.bold: true
        }
      }
      Component {
        id: layoutComp
        Text {
          readonly property bool shown: !!(win.notch && win.notch.kbLayout)
          text: win.notch ? win.notch.kbLayout : ""
          color: Qt.darker(win.fg, 1.2)
          font.family: win.ff; font.pixelSize: Style.font.caption; font.bold: true
        }
      }
      Component {
        id: shelfComp
        Row {
          readonly property bool shown: !!(ears.shelfMod && ears.shelfMod.active && ears.shelfMod.items.length)
          spacing: Style.space(3)
          Text { anchors.verticalCenter: parent.verticalCenter; text: "\u{f0120}"; color: win.accent; font.family: win.ff; font.pixelSize: Style.font.body }
          Text { anchors.verticalCenter: parent.verticalCenter; text: ears.shelfMod ? ears.shelfMod.items.length : ""; color: win.fg; font.family: win.ff; font.pixelSize: Style.font.caption; font.bold: true }
          TapHandler { onTapped: win.notch.openModule("shelf") }
        }
      }
      Component {
        id: micComp
        Text {
          readonly property bool shown: ears.micOff
          text: "\u{f036d}"; color: Color.urgent
          font.family: win.ff; font.pixelSize: Style.font.body
        }
      }
      Component {
        id: privacyComp
        Grid {
          id: privDots
          readonly property bool shown: win.priv
          rows: win.vertical ? 2 : 1
          columns: win.vertical ? 1 : 2
          spacing: Style.space(4)
          component Dot: Rectangle {
            property color tone: "orange"
            property string glyph: ""
            width: Style.space(18); height: width; radius: width / 2
            color: Qt.rgba(tone.r, tone.g, tone.b, 0.22)
            Text { anchors.centerIn: parent; text: parent.glyph; color: parent.tone; font.family: win.ff; font.pixelSize: Style.font.caption - 1 }
            SequentialAnimation on opacity {
              loops: Animation.Infinite; running: privDots.visible
              NumberAnimation { to: 0.55; duration: 1200; easing.type: Easing.InOutSine }
              NumberAnimation { to: 1; duration: 1200; easing.type: Easing.InOutSine }
            }
          }
          Dot { visible: win.priv && win.notch.privacy.mic.length > 0; tone: win.notch && win.notch.privacy ? win.notch.privacy.micColor : "orange"; glyph: "\u{f036c}" }
          Dot { visible: win.priv && win.notch.privacy.cam.length > 0; tone: win.notch && win.notch.privacy ? win.notch.privacy.camColor : "green"; glyph: "\u{f0567}" }
          HoverHandler { onHoveredChanged: if (hovered) win.notch.privacyHover = true }
        }
      }
    }

    // ---------------------------------------------- drop onto the shelf
    DropArea {
      anchors.fill: parent
      enabled: win.notch !== null && win.mode !== "expanded" && ears.shelfMod !== null && ears.shelfMod.active
      onEntered: win.notch.dropHover = true
      onExited: win.notch.dropHover = false
      onDropped: function(ev) { win.notch.dropHover = false; ears.shelfMod.take(ev.urls, ev.text); ev.acceptProposedAction() }
    }
    Row {
      visible: win.notch !== null && win.notch.dropHover
      anchors.centerIn: parent
      spacing: Style.space(10)
      Text { anchors.verticalCenter: parent.verticalCenter; text: "\u{f0120}"; color: win.accent; font.family: win.ff; font.pixelSize: Style.space(22) }
      Text { anchors.verticalCenter: parent.verticalCenter; text: win.notch && win.notch.lang === "ru" ? "Положить на полку" : "Put it on the shelf"; color: win.fg; font.family: win.ff; font.pixelSize: Style.font.body; font.bold: true }
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
      active: win.peekMod !== null
      sourceComponent: win.peekMod ? win.peekMod.peek : null
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
      // the other dashboards are tools in Centre now; this keeps the anchor
      Item { id: icons; anchors.right: gear.left; anchors.rightMargin: Style.space(8); width: 0; height: 30 }
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
          onClicked: win.notch.openSettings("")
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
        // one page per module, built the first time it's shown; the main tabs
        // are then kept, so switching between them only shows another one
        // (rebuilding each time made every switch stutter); tools unload
        Item {
          id: expandedPage
          width: pageArea.width
          readonly property var item: { var ls = pageLoaders; for (var i = 0; i < pages.count; i++) { var l = pages.itemAt(i); if (l && l.isCur) return l.item } return null }
          property int pageLoaders: 0
          height: item ? item.implicitHeight : 0
          Repeater {
            id: pages
            model: win.notch ? win.notch.modules.filter(function(m) { return m.page !== null && m.page !== undefined }) : []
            delegate: Loader {
              id: pageLoader
              required property var modelData
              readonly property bool isCur: win.cur === modelData
              property bool visited: false
              function visit() { if (isCur && win.mode === "expanded") visited = true }
              onIsCurChanged: visit()
              Connections { target: win; function onModeChanged() { pageLoader.visit() } }
              Component.onCompleted: visit()
              // the main tabs stay built; tools (notes, shelf…) unload after use
              active: visited && (modelData.topTab || isCur)
              visible: isCur
              width: pageArea.width
              sourceComponent: modelData.page
              onLoaded: expandedPage.pageLoaders++
            }
          }
        }
      }
    }
  }
}
