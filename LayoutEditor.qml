import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import "../osia.soundhub" as SH

// Widget layout editor for one monitor: over everything, a dimmed desktop
// with a grid; the real widgets can be dragged and snap ("magnet") to the
// grid, the screen's edges and centre, and the edges and centres of the
// other widgets — the guides they snap to light up. Widgets never overlap:
// a drop on top of another moves to the nearest free spot. The bar on top
// switches widgets on/off for this monitor; Esc or Done ends editing.
PanelWindow {
  id: ed
  property var notch: null

  color: "transparent"
  anchors { top: true; bottom: true; left: true; right: true }
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "osia-thenotch-layout"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

  readonly property string screenName: screen ? String(screen.name) : ""
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Style.font.family
  readonly property bool ru: notch !== null && notch.lang === "ru"
  readonly property real step: Style.space(40)
  readonly property real edgeM: Style.space(24)
  readonly property real gap: Style.space(16)
  readonly property real pull: Style.space(14)       // magnet reach

  // widgets placed on this monitor (enabled ones)
  readonly property var here: notch ? notch.deskItems.filter(function(d) {
    if (!d.enabled) return false
    var p = notch.placesOf(d.wid)
    return p.length ? p.indexOf(ed.screenName) >= 0 : ed.screenName === notch.notchScreen
  }) : []

  property var guidesX: []
  // the tray of widgets on the left: drag one out to place it, drag a placed
  // one back in to take it off this monitor
  property bool trayOpen: false
  property bool dragging: false                       // a placed widget is being dragged
  readonly property bool trayShown: trayOpen
  readonly property real trayW: Style.space(270)
  // where a dragged widget can be dropped to take it off: the drop zone at the
  // bottom left (shown while dragging), or the open tray
  function overTray(x, y) {
    if (dragging && y !== undefined && x < dropZone.x + dropZone.width + Style.space(10) && y > dropZone.y - Style.space(10)) return true
    return trayShown && x < tray.x + tray.width + Style.space(10) && (y === undefined || (y > tray.y && y < tray.y + tray.height))
  }
  function placeHere(wid, x, y) {
    var it = notch.deskItem(wid)
    if (it && !it.enabled) it.setEnabled(true)
    notch.setOnScreen(wid, screenName, true)
    if (x !== undefined) notch.setPos(wid, screenName, Math.max(trayShown ? trayW + Style.space(24) : 0, x), y)
    else {                                        // a click: the nearest free spot around the middle
      var f = freeSpot(wid, Math.round(width / 2 - Style.space(110)), Math.round(height / 2 - Style.space(60)), Style.space(220), Style.space(120))
      notch.setPos(wid, screenName, f.x, f.y)
    }
    notch.layoutPick = wid
  }
  function takeAway(wid) {
    if (notch.placesOf(wid).length <= 1) { var it = notch.deskItem(wid); if (it) it.setEnabled(false) }
    notch.setOnScreen(wid, screenName, false)
    if (notch.layoutPick === wid) notch.layoutPick = ""
  }
  // the widget whose settings panel is open (click a widget to pick it)
  readonly property string selected: notch ? notch.layoutPick : ""
  function proxyOf(wid) { for (var i = 0; i < proxies.count; i++) { var p = proxies.itemAt(i); if (p && p.wid === wid) return p } return null }
  readonly property var selItem: { var s = selected; return s ? here.filter(function(d) { return d.wid === s })[0] || null : null }
  property var guidesY: []

  // ------------------------------------------------------------ backdrop
  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.55)
    MouseArea { anchors.fill: parent; onClicked: ed.notch.layoutPick = "" }
  }
  Canvas {
    id: grid
    anchors.fill: parent
    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      for (var x = ed.edgeM; x <= width - ed.edgeM + 0.5; x += ed.step)
        for (var y = ed.edgeM; y <= height - ed.edgeM + 0.5; y += ed.step) {
          var major = Math.round((x - ed.edgeM) / ed.step) % 4 === 0 && Math.round((y - ed.edgeM) / ed.step) % 4 === 0
          ctx.fillStyle = major ? Qt.rgba(1, 1, 1, 0.35) : Qt.rgba(1, 1, 1, 0.14)
          var r = major ? 2 : 1.2
          ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.fill()
        }
      ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.10); ctx.setLineDash([4, 6]); ctx.lineWidth = 1
      ctx.beginPath(); ctx.moveTo(width / 2, 0); ctx.lineTo(width / 2, height); ctx.stroke()
      ctx.beginPath(); ctx.moveTo(0, height / 2); ctx.lineTo(width, height / 2); ctx.stroke()
    }
    Component.onCompleted: requestPaint()
    onWidthChanged: requestPaint()
  }
  // snap guides
  Repeater {
    model: ed.guidesX
    delegate: Rectangle { required property var modelData; x: modelData - 1; y: 0; width: 2; height: ed.height; color: ed.accent; opacity: 0.8 }
  }
  Repeater {
    model: ed.guidesY
    delegate: Rectangle { required property var modelData; y: modelData - 1; x: 0; height: 2; width: ed.width; color: ed.accent; opacity: 0.8 }
  }

  // ------------------------------------------------------------- snapping
  function others(id) {
    var out = []
    for (var i = 0; i < proxies.count; i++) {
      var p = proxies.itemAt(i)
      if (p && p.wid !== id) out.push({ x: p.x, y: p.y, w: p.width, h: p.height })
    }
    return out
  }
  // candidate spots for one axis: [value, guide line]
  function axis(v, size, full, os, isX) {
    var c = [[edgeM, edgeM], [full - edgeM - size, full - edgeM], [(full - size) / 2, full / 2]]
    for (var i = 0; i < os.length; i++) {
      var o = os[i], a = isX ? o.x : o.y, s = isX ? o.w : o.h
      c.push([a, a]); c.push([a + s - size, a + s]); c.push([a + s / 2 - size / 2, a + s / 2])
      c.push([a + s + gap, a + s + gap / 2]); c.push([a - size - gap, a - gap / 2])
    }
    var best = null
    for (var j = 0; j < c.length; j++) {
      var d = Math.abs(c[j][0] - v)
      if (d <= pull && (!best || d < best.d)) best = { v: c[j][0], line: c[j][1], d: d }
    }
    if (best) return best
    return { v: edgeM + Math.round((v - edgeM) / step) * step, line: -1 }   // the grid's own pull
  }
  function snap(id, x, y, w, h) {
    var os = others(id)
    var sx = axis(x, w, width, os, true), sy = axis(y, h, height, os, false)
    guidesX = sx.line >= 0 ? [sx.line] : []
    guidesY = sy.line >= 0 ? [sy.line] : []
    return { x: Math.max(0, Math.min(width - w, sx.v)), y: Math.max(0, Math.min(height - h, sy.v)) }
  }
  function overlaps(id, x, y, w, h) {
    var os = others(id), g = Style.space(8)
    for (var i = 0; i < os.length; i++) {
      var o = os[i]
      if (x < o.x + o.w + g && x + w + g > o.x && y < o.y + o.h + g && y + h + g > o.y) return true
    }
    return false
  }
  // nearest free spot on the grid, spiralling out from (x, y)
  function freeSpot(id, x, y, w, h) {
    if (!overlaps(id, x, y, w, h)) return { x: x, y: y }
    for (var r = 1; r < 40; r++)
      for (var dx = -r; dx <= r; dx++)
        for (var dy = -r; dy <= r; dy++) {
          if (Math.abs(dx) !== r && Math.abs(dy) !== r) continue
          var nx = Math.max(0, Math.min(width - w, x + dx * step)), ny = Math.max(0, Math.min(height - h, y + dy * step))
          if (!overlaps(id, nx, ny, w, h)) return { x: nx, y: ny }
        }
    return { x: x, y: y }
  }

  // --------------------------------------------------------------- widgets
  Repeater {
    id: proxies
    model: ed.here
    delegate: Item {
      id: px
      required property var modelData
      readonly property string wid: modelData.wid
      readonly property var start: ed.notch.posOf(wid, ed.screenName)
      property real rot: start.rot || 0
      readonly property bool locked: start.lock === true
      property bool canVertical: false
      readonly property var turnInfo: ed.notch.turnOf(rot, canVertical)   // not "turn": the rotate handle has that id
      readonly property real sc: start.scale || 1
      readonly property real ks: content.item && ("deskScale" in content.item) ? 1 : sc
      readonly property real cw: content.item ? content.item.width * ks : 60
      readonly property real ch: content.item ? content.item.height * ks : 40
      readonly property real rad: turnInfo.rot * Math.PI / 180
      readonly property var at: ed.notch.anchored(start, realW, realH, ed.screen ? ed.screen.width : ed.width, ed.screen ? ed.screen.height : ed.height)
      // the real box (the frame below has a minimum size)
      readonly property real realW: Math.abs(cw * Math.cos(rad)) + Math.abs(ch * Math.sin(rad))
      readonly property real realH: Math.abs(cw * Math.sin(rad)) + Math.abs(ch * Math.cos(rad))
      x: at.x; y: at.y
      width: Math.max(Style.space(60), Math.abs(cw * Math.cos(rad)) + Math.abs(ch * Math.sin(rad)))
      height: Math.max(Style.space(40), Math.abs(cw * Math.sin(rad)) + Math.abs(ch * Math.cos(rad)))
      Behavior on x { enabled: !drag.pressed; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
      Behavior on y { enabled: !drag.pressed; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
      z: drag.pressed ? 10 : 1

      onTurnInfoChanged: feed()
      // turn or resize around the widget's centre, keep it on screen, save
      function reshape(values) {
        var cx = x + realW / 2, cy = y + realH / 2
        if (values.rot !== undefined) rot = values.rot
        var s = values.scale !== undefined ? values.scale : sc
        // sizes for the new angle/scale (bindings update right away for rot; scale is from the layout)
        var k = s / sc, w = realW * k, h = realH * k
        var f = ed.freeSpot(wid, Math.max(0, Math.min(ed.width - w, cx - w / 2)), Math.max(0, Math.min(ed.height - h, cy - h / 2)), w, h)
        x = f.x; y = f.y
        var v = { rot: Math.round(rot), x: Math.round(f.x), y: Math.round(f.y), w: Math.round(w), h: Math.round(h) }
        if (values.scale !== undefined) v.scale = Math.round(s * 100) / 100
        ed.notch.patchPlace(wid, ed.screenName, v)
      }
      Loader {
        id: content
        anchors.centerIn: parent
        rotation: px.turnInfo.rot
        scale: px.ks
        opacity: ed.notch.styleOf(px.wid).opacity !== undefined ? Number(ed.notch.styleOf(px.wid).opacity) : 1
        sourceComponent: px.modelData.component
        onLoaded: { px.canVertical = "deskVertical" in item; px.feed() }
      }
      function feed() {
        var it = content.item
        if (!it) return
        if ("editing" in it) it.editing = true
        if ("deskVertical" in it) it.deskVertical = px.turnInfo.vertical
        if ("deskStyle" in it) it.deskStyle = Qt.binding(function() { return ed.notch.styleOf(px.wid) })
        if ("deskId" in it) it.deskId = px.wid
        if ("deskScale" in it) it.deskScale = Qt.binding(function() { return px.sc })
        // the screen's size, not this window's (still 0 × 0 while it maps)
        var sw = ed.screen ? ed.screen.width : ed.width, sh = ed.screen ? ed.screen.height : ed.height
        if ("screenW" in it) it.screenW = sw
        if ("screenH" in it) it.screenH = sh
        if ("fx" in it) it.fx = (px.x + px.width / 2) / Math.max(1, sw)
        if ("fy" in it) it.fy = (px.y + px.height / 2) / Math.max(1, sh)
      }
      Rectangle {                                    // frame
        anchors.fill: parent
        anchors.margins: -Style.space(6)
        radius: SH.HubStyle.radius + Style.space(4)
        color: "transparent"
        border.width: 2
        border.color: drag.pressed || ed.selected === px.wid ? ed.accent
                    : px.locked ? SH.HubStyle.tint(ed.fg, 0.2) : SH.HubStyle.tint(ed.fg, drag.containsMouse ? 0.7 : 0.35)
      }
      MouseArea {
        id: drag
        anchors.fill: parent
        anchors.margins: -Style.space(6)
        hoverEnabled: true
        cursorShape: px.locked ? Qt.PointingHandCursor : pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        property real ox: 0
        property real oy: 0
        onPressed: function(m) { ox = m.x; oy = m.y; ed.notch.layoutPick = px.wid }
        onPressedChanged: ed.dragging = pressed && !px.locked
        onPositionChanged: function(m) {
          if (!pressed || px.locked) return
          var p = mapToItem(null, m.x, m.y)
          var s = ed.snap(px.wid, p.x - ox + Style.space(6), p.y - oy + Style.space(6), px.width, px.height)
          px.x = s.x; px.y = s.y
          px.feed()
        }
        onReleased: function(m) {
          ed.guidesX = []; ed.guidesY = []
          if (px.locked) return
          var at = mapToItem(null, m.x, m.y)
          if (ed.overTray(at.x, at.y)) { ed.takeAway(px.wid); return }
          var f = ed.freeSpot(px.wid, px.x, px.y, px.width, px.height)
          px.x = f.x; px.y = f.y
          ed.notch.setPos(px.wid, ed.screenName, f.x, f.y, px.realW, px.realH)
          px.feed()
        }
      }
      // name + lock, above the frame
      Row {
        anchors.bottom: parent.top; anchors.bottomMargin: Style.space(10)
        anchors.left: parent.left
        spacing: Style.space(4)
        Rectangle {
          width: tag.implicitWidth + Style.space(16); height: tag.implicitHeight + Style.space(6)
          radius: height / 2
          color: drag.pressed ? ed.accent : SH.HubStyle.tint(ed.bgc, 0.9)
          Text {
            id: tag
            anchors.centerIn: parent
            text: px.modelData.icon + "  " + px.modelData.title + (px.rot ? "  ·  " + Math.round(px.rot) + "°" : "")
            color: drag.pressed ? ed.bgc : ed.fg
            font.family: ed.ff; font.pixelSize: Style.font.caption - 1; font.bold: true
          }
        }
        Rectangle {
          width: height; height: tag.implicitHeight + Style.space(6)
          radius: height / 2
          color: px.locked ? ed.accent : SH.HubStyle.tint(ed.bgc, 0.9)
          Text {
            anchors.centerIn: parent
            text: px.locked ? "\u{f033e}" : "\u{f0fc6}"            // lock / lock-open
            color: px.locked ? ed.bgc : ed.fg
            font.family: ed.ff; font.pixelSize: Style.font.caption
          }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: ed.notch.setLock(px.wid, ed.screenName, !px.locked)
          }
        }
      }

    }
  }

  // ------------------------------------------------------------------ tray
  Rectangle {
    id: tray
    z: 18
    x: ed.trayShown ? Style.space(14) : -width - Style.space(20)
    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    y: Style.space(170)
    width: ed.trayW
    height: Math.min(ed.height * 0.6, trayCol.implicitHeight + Style.space(26))
    radius: SH.HubStyle.radius + Style.space(4)
    color: ed.bgc
    border.width: 1
    border.color: SH.HubStyle.tint(ed.fg, 0.14)
    MouseArea { anchors.fill: parent }
    Flickable {
      anchors.fill: parent
      anchors.margins: Style.space(12)
      contentHeight: trayCol.implicitHeight
      clip: true
      interactive: contentHeight > height
      boundsBehavior: Flickable.StopAtBounds
      Column {
        id: trayCol
        width: parent.width
        spacing: Style.space(6)
        Text { text: "\u{f072c}  " + (ed.ru ? "Виджеты" : "Widgets"); color: ed.fg; font.family: ed.ff; font.pixelSize: Style.font.body + 1; font.bold: true }
        Text {
          width: parent.width; wrapMode: Text.Wrap
          text: ed.ru ? "Перетащите на стол или нажмите, чтобы поставить" : "Drag onto the desktop, or click to place"
          color: Qt.darker(ed.fg, 1.6); font.family: ed.ff; font.pixelSize: Style.font.caption - 1
        }
        Repeater {
          model: ed.notch ? ed.notch.deskItems : []
          delegate: Rectangle {
            id: card
            required property var modelData
            readonly property bool here: ed.here.some(function(d) { return d.wid === modelData.wid })
            width: trayCol.width; height: Style.space(46)
            radius: SH.HubStyle.radiusSmall + Style.space(2)
            color: here ? SH.HubStyle.tint(ed.accent, 0.18) : SH.HubStyle.tint(ed.fg, cardMouse.containsMouse ? 0.10 : 0.05)
            Row {
              anchors.verticalCenter: parent.verticalCenter
              x: Style.space(12)
              spacing: Style.space(10)
              Text { anchors.verticalCenter: parent.verticalCenter; text: card.modelData.icon; color: card.here ? ed.accent : ed.fg; font.family: ed.ff; font.pixelSize: Style.font.body + 3 }
              Column {
                anchors.verticalCenter: parent.verticalCenter
                Text { text: card.modelData.title; color: ed.fg; font.family: ed.ff; font.pixelSize: Style.font.caption + 1; font.bold: card.here; width: trayCol.width - Style.space(60); elide: Text.ElideRight }
                Text {
                  text: card.here ? (ed.ru ? "на этом мониторе" : "on this monitor") : (ed.ru ? "не на столе" : "not placed")
                  color: card.here ? ed.accent : Qt.darker(ed.fg, 1.6); font.family: ed.ff; font.pixelSize: Style.font.caption - 2
                }
              }
            }
            MouseArea {
              id: cardMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
              property bool moved: false
              onPressed: function(m) { moved = false; ghost.label = card.modelData.icon + "  " + card.modelData.title }
              onPositionChanged: function(m) {
                if (!pressed) return
                var p = mapToItem(ed.contentItem, m.x, m.y)
                if (!moved && p.x > tray.x + tray.width) moved = true
                ghost.x = p.x - ghost.width / 2; ghost.y = p.y - ghost.height / 2
                ghost.visible = moved
              }
              onReleased: function(m) {
                var p = mapToItem(ed.contentItem, m.x, m.y)
                ghost.visible = false
                if (moved && !ed.overTray(p.x, p.y)) ed.placeHere(card.modelData.wid, Math.round(p.x - Style.space(40)), Math.round(p.y - Style.space(20)))
                else if (!moved) { if (card.here) ed.notch.layoutPick = card.modelData.wid; else ed.placeHere(card.modelData.wid) }
              }
            }
          }
        }
        Item { width: 1; height: Style.space(8) }
        Text { text: "\u{f0416}  " + (ed.ru ? "Свой виджет" : "Your own widget"); color: ed.fg; font.family: ed.ff; font.pixelSize: Style.font.body + 1; font.bold: true }
        Flow {
          width: parent.width
          spacing: Style.space(6)
          Repeater {
            model: ["text", "command", "image", "note"]
            delegate: SH.HubChip {
              required property string modelData
              icon: ed.notch.customIcon(modelData); label: ed.notch.customTitle(modelData)
              subtle: true
              h: Style.space(28)
              fg: ed.fg; accent: ed.accent; fontFamily: ed.ff
              onClicked: { var wid = ed.notch.addCustom(modelData); placeLater.wid = wid; placeLater.restart() }
            }
          }
        }
        Timer { id: placeLater; property string wid: ""; interval: 150; onTriggered: ed.placeHere(wid) }
      }
    }
  }
  // while a placed widget is dragged: drop it here to take it off this monitor
  Rectangle {
    id: dropZone
    z: 19
    visible: ed.dragging
    x: Style.space(24); y: ed.height - height - Style.space(24)
    width: dz.implicitWidth + Style.space(36); height: Style.space(52)
    radius: height / 2
    color: SH.HubStyle.tint(ed.accent, 0.25)
    border.width: 2; border.color: ed.accent
    Text { id: dz; anchors.centerIn: parent; text: "\u{f01b4}  " + (ed.ru ? "Убрать в корзину" : "Put back in the tray"); color: ed.fg; font.family: ed.ff; font.pixelSize: Style.font.body; font.bold: true }
  }
  // what follows the pointer while a widget is dragged out of the tray
  Rectangle {
    id: ghost
    property string label: ""
    visible: false
    z: 30
    width: gl.implicitWidth + Style.space(28); height: Style.space(40)
    radius: height / 2
    color: ed.accent
    Text { id: gl; anchors.centerIn: parent; text: ghost.label; color: ed.bgc; font.family: ed.ff; font.pixelSize: Style.font.body; font.bold: true }
  }

  // ------------------------------------------------- the picked widget's panel
  // next to the widget: turn, lock, scale and the widget's own settings
  Rectangle {
    id: panel
    readonly property var px: ed.selected ? ed.proxyOf(ed.selected) : null
    visible: px !== null && ed.selItem !== null
    z: 15
    width: Style.space(340)
    height: Math.min(ed.height - Style.space(40), pcol.implicitHeight + Style.space(24))
    readonly property real side: Style.space(18)
    x: !px ? 0 : (px.x + px.width + side + width <= ed.width ? px.x + px.width + side : Math.max(0, px.x - side - width))
    y: !px ? 0 : Math.max(Style.space(20), Math.min(ed.height - height - Style.space(20), px.y))
    radius: SH.HubStyle.radius + Style.space(4)
    color: ed.bgc
    border.width: 1
    border.color: SH.HubStyle.tint(ed.fg, 0.14)
    MouseArea { anchors.fill: parent }                 // clicks stay in the panel
    Flickable {
      anchors.fill: parent
      anchors.margins: Style.space(12)
      contentHeight: pcol.implicitHeight
      clip: true
      interactive: contentHeight > height
      boundsBehavior: Flickable.StopAtBounds
      Column {
        id: pcol
        width: parent.width
        spacing: Style.space(10)
        Item {
          width: parent.width; height: Style.space(28)
          Text {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - tools.width - Style.space(8)
            elide: Text.ElideRight
            text: ed.selItem ? ed.selItem.icon + "  " + ed.selItem.title : ""
            color: ed.fg
            font.family: ed.ff; font.pixelSize: Style.font.body; font.bold: true
          }
          Row {
            id: tools
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(4)
            Repeater {
              model: [{ id: "left", icon: "\u{f0465}", tip: ed.ru ? "Повернуть влево на 90°" : "Turn left 90°" },
                      { id: "right", icon: "\u{f0467}", tip: ed.ru ? "Повернуть вправо на 90°" : "Turn right 90°" },
                      { id: "zero", icon: "\u{f099b}", tip: ed.ru ? "Без поворота" : "No rotation" },
                      { id: "lock", icon: panel.px && panel.px.locked ? "\u{f033e}" : "\u{f0fc6}", tip: ed.ru ? "Закрепить" : "Pin" },
                      { id: "close", icon: "󰅖", tip: ed.ru ? "Закрыть" : "Close" }]
              delegate: SH.HubChip {
                required property var modelData
                iconOnly: true
                icon: modelData.icon; label: modelData.tip
                on: modelData.id === "lock" && panel.px && panel.px.locked
                h: Style.space(28)
                fg: ed.fg; accent: ed.accent; ink: ed.bgc; fontFamily: ed.ff
                onClicked: {
                  var p = panel.px
                  if (!p) return
                  var norm = function(r) { return ((r % 360) + 540) % 360 - 180 }
                  if (modelData.id === "left") p.reshape({ rot: norm(Math.round((p.rot - 90) / 90) * 90) })
                  else if (modelData.id === "right") p.reshape({ rot: norm(Math.round((p.rot + 90) / 90) * 90) })
                  else if (modelData.id === "zero") p.reshape({ rot: 0 })
                  else if (modelData.id === "lock") ed.notch.setLock(p.wid, ed.screenName, !p.locked)
                  else ed.notch.layoutPick = ""
                }
              }
            }
          }
        }
        // three tabs: the widget's own settings, its look, its place
        property string tab: "look"
        Row {
          spacing: Style.space(4)
          Repeater {
            model: [{ id: "look", label: ed.ru ? "Вид" : "Look" }, { id: "style", label: ed.ru ? "Оформление" : "Style" },
                    { id: "place", label: ed.ru ? "Место" : "Place" }]
            delegate: SH.HubChip {
              required property var modelData
              label: modelData.label
              on: pcol.tab === modelData.id
              h: Style.space(28)
              fg: ed.fg; accent: ed.accent; ink: ed.bgc; fontFamily: ed.ff
              onClicked: pcol.tab = modelData.id
            }
          }
        }
        Rectangle { width: parent.width; height: 1; color: SH.HubStyle.tint(ed.fg, 0.08) }

        // ---- look: the widget's own settings
        Loader {
          visible: pcol.tab === "look"
          width: parent.width
          active: panel.visible && !!(ed.selItem && ed.selItem.page)
          sourceComponent: ed.selItem ? ed.selItem.page : null
          onLoaded: item.width = Qt.binding(function() { return width })
        }
        Text {
          visible: pcol.tab === "look" && !(ed.selItem && ed.selItem.page)
          text: ed.ru ? "У этого виджета нет своих настроек" : "This widget has no settings of its own"
          color: Qt.darker(ed.fg, 1.6); font.family: ed.ff; font.pixelSize: Style.font.caption
        }

        // ---- style: the look every widget shares (DeskStyle.js)
        Column {
          visible: pcol.tab === "style"
          width: parent.width
          spacing: Style.space(6)
          readonly property var st: ed.selected ? ed.notch.styleOf(ed.selected) : ({})
          function set(v) { ed.notch.setStyle(ed.selected, v) }
          component Swatches: Row {
            id: sw
            property string key: ""
            property string current: "theme"
            property bool withAccent: true
            spacing: Style.space(5)
            Repeater {
              model: ["theme"].concat(sw.withAccent ? ["accent"] : []).concat(["#000000", "#ffffff", "#e06c75", "#e5b450", "#98c379", "#61afef", "#c678dd"])
              delegate: Rectangle {
                required property string modelData
                readonly property bool on: sw.current === modelData
                width: Style.space(22); height: width; radius: width / 2
                color: modelData === "theme" ? "transparent" : modelData === "accent" ? ed.accent : modelData
                border.width: on ? 3 : 1
                border.color: on ? ed.accent : SH.HubStyle.tint(ed.fg, 0.3)
                Text { visible: modelData === "theme"; anchors.centerIn: parent; text: "\u{f03d8}"; color: ed.fg; font.family: ed.ff; font.pixelSize: Style.font.caption }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { var v = {}; v[sw.key] = modelData === "theme" ? null : modelData; styleCol.set(v) } }
              }
            }
          }
          id: styleCol
          SH.HubRow { title: ed.ru ? "Фон" : "Background"; fg: ed.fg; fontFamily: ed.ff
            Swatches { key: "bg"; current: styleCol.st.bg || "theme" } }
          SH.HubRow { title: ed.ru ? "Прозрачность фона" : "Background opacity"; fg: ed.fg; fontFamily: ed.ff
            SH.HubSlider { width: Style.space(150); minimum: 0; maximum: 1; step: 0.05
              value: styleCol.st.bgOpacity !== undefined ? Number(styleCol.st.bgOpacity) : 0.85
              fillColor: ed.accent; fontFamily: ed.ff
              onReleased: function(v) { styleCol.set({ bgOpacity: Math.round(v * 100) / 100 }) } } }
          SH.HubRow { title: ed.ru ? "Скругление" : "Corners"; fg: ed.fg; fontFamily: ed.ff
            SH.HubSlider { width: Style.space(150); minimum: 0; maximum: 48; step: 1
              value: styleCol.st.radius !== undefined ? Number(styleCol.st.radius) : 16
              format: function(v) { return Math.round(v) + " px" }
              fillColor: ed.accent; fontFamily: ed.ff
              onReleased: function(v) { styleCol.set({ radius: Math.round(v) }) } } }
          SH.HubRow { title: ed.ru ? "Углы по отдельности" : "Corners one by one"; fg: ed.fg; fontFamily: ed.ff
            SH.HubSwitch {
              checked: !!styleCol.st.corners
              fg: ed.fg; accent: ed.accent; ink: ed.bgc
              onToggled: {
                var r = styleCol.st.radius !== undefined ? Number(styleCol.st.radius) : 16
                styleCol.set({ corners: checked ? null : { tl: r, tr: r, bl: r, br: r } })
              }
            } }
          Repeater {
            model: styleCol.st.corners ? [{ k: "tl", l: ed.ru ? "↖ Левый верхний" : "↖ Top left" }, { k: "tr", l: ed.ru ? "↗ Правый верхний" : "↗ Top right" },
                                          { k: "bl", l: ed.ru ? "↙ Левый нижний" : "↙ Bottom left" }, { k: "br", l: ed.ru ? "↘ Правый нижний" : "↘ Bottom right" }] : []
            delegate: SH.HubRow {
              required property var modelData
              title: modelData.l; fg: ed.fg; fontFamily: ed.ff
              SH.HubSlider { width: Style.space(150); minimum: 0; maximum: 64; step: 1
                value: Number(styleCol.st.corners[modelData.k] || 0)
                format: function(v) { return Math.round(v) + " px" }
                fillColor: ed.accent; fontFamily: ed.ff
                onReleased: function(v) { var c = Object.assign({}, styleCol.st.corners); c[modelData.k] = Math.round(v); styleCol.set({ corners: c }) } }
            }
          }
          SH.HubRow { title: ed.ru ? "Рамка" : "Border"; fg: ed.fg; fontFamily: ed.ff
            SH.HubSwitch { checked: styleCol.st.border !== false; fg: ed.fg; accent: ed.accent; ink: ed.bgc; onToggled: styleCol.set({ border: !checked }) } }
          SH.HubRow { title: ed.ru ? "Тень" : "Shadow"; fg: ed.fg; fontFamily: ed.ff
            SH.HubSwitch { checked: styleCol.st.shadow === true; fg: ed.fg; accent: ed.accent; ink: ed.bgc; onToggled: styleCol.set({ shadow: !checked }) } }
          SH.HubRow { title: ed.ru ? "Прозрачность виджета" : "Widget opacity"; fg: ed.fg; fontFamily: ed.ff
            SH.HubSlider { width: Style.space(150); minimum: 0.2; maximum: 1; step: 0.05
              value: styleCol.st.opacity !== undefined ? Number(styleCol.st.opacity) : 1
              fillColor: ed.accent; fontFamily: ed.ff
              onReleased: function(v) { styleCol.set({ opacity: Math.round(v * 100) / 100 }) } } }
          SH.HubRow { title: ed.ru ? "Цвет текста" : "Text colour"; fg: ed.fg; fontFamily: ed.ff
            Swatches { key: "text"; withAccent: false; current: styleCol.st.text || "theme" } }
          SH.HubRow { title: ed.ru ? "Акцент" : "Accent"; fg: ed.fg; fontFamily: ed.ff
            Swatches { key: "accent"; withAccent: false; current: styleCol.st.accent || "theme" } }
          SH.HubChip {
            icon: "\u{f099b}"; label: ed.ru ? "Сбросить оформление" : "Reset the style"
            h: Style.space(28)
            fg: ed.fg; accent: ed.accent; fontFamily: ed.ff
            onClicked: { var v = {}; for (var k in styleCol.st) v[k] = null; styleCol.set(v) }
          }
        }

        // ---- place: turn, scale, lock
        Column {
          visible: pcol.tab === "place"
          width: parent.width
          spacing: Style.space(6)
          SH.HubRow {
            title: ed.ru ? "Масштаб" : "Scale"
            fg: ed.fg; fontFamily: ed.ff
            SH.HubSlider {
              width: Style.space(170)
              minimum: 0.5; maximum: 2; step: 0.05
              value: panel.px ? panel.px.sc : 1
              fillColor: ed.accent; fontFamily: ed.ff
              onReleased: function(v) { if (panel.px) panel.px.reshape({ scale: v }) }
            }
          }
          Text {
            width: parent.width; wrapMode: Text.Wrap
            text: ed.ru ? "Поворот и замок — кнопками вверху панели; на 90° виджет перестраивается вертикально"
                        : "Turn and lock with the buttons on top; at 90° the widget switches to its vertical layout"
            color: Qt.darker(ed.fg, 1.6); font.family: ed.ff; font.pixelSize: Style.font.caption - 1
          }
        }
      }
    }
  }

  // ---------------------------------------------------------------- toolbar
  Rectangle {
    id: bar
    anchors.top: parent.top; anchors.topMargin: Style.space(60)
    anchors.horizontalCenter: parent.horizontalCenter
    width: barRow.implicitWidth + Style.space(28)
    height: barCol.implicitHeight + Style.space(24)
    radius: SH.HubStyle.radius + Style.space(6)
    color: ed.bgc
    border.width: 1
    border.color: SH.HubStyle.tint(ed.fg, 0.12)
    z: 20
    Column {
      id: barCol
      anchors.centerIn: parent
      spacing: Style.space(8)
      Row {
        id: barRow
        spacing: Style.space(8)
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "\u{f072c}  " + (ed.ru ? "Виджеты · " : "Widgets · ") + ed.screenName
          color: ed.fg
          font.family: ed.ff; font.pixelSize: Style.font.body; font.bold: true
          rightPadding: Style.space(8)
        }
        SH.HubChip {
          icon: "\u{f072c}"
          label: ed.ru ? "Корзина виджетов" : "Widget tray"
          on: ed.trayOpen
          h: Style.space(28)
          fg: ed.fg; accent: ed.accent; ink: ed.bgc; fontFamily: ed.ff
          onClicked: ed.trayOpen = !ed.trayOpen
        }
        SH.HubChip {
          icon: "󰄬"
          label: ed.ru ? "Готово" : "Done"
          on: true
          h: Style.space(28)
          fg: ed.fg; accent: ed.accent; ink: ed.bgc; fontFamily: ed.ff
          onClicked: ed.notch.editLayout(false)
        }
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: ed.ru ? "Тяните виджеты — они липнут к сетке и друг к другу · клик — настройки рядом · из корзины — на стол, со стола — в корзину · Esc — готово"
                    : "Drag widgets — they stick to the grid and each other · click — settings beside it · tray to desk, desk to tray · Esc — done"
        color: Qt.darker(ed.fg, 1.6)
        font.family: ed.ff; font.pixelSize: Style.font.caption - 1
      }
    }
  }

  Item {
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: if (ed.selected) ed.notch.layoutPick = ""; else ed.notch.editLayout(false)
  }
}
