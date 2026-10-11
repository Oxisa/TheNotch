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
  // the widget whose settings panel is open (click a widget to pick it)
  property string selected: ""
  function proxyOf(wid) { for (var i = 0; i < proxies.count; i++) { var p = proxies.itemAt(i); if (p && p.wid === wid) return p } return null }
  readonly property var selItem: { var s = selected; return s ? here.filter(function(d) { return d.wid === s })[0] || null : null }
  property var guidesY: []

  // ------------------------------------------------------------ backdrop
  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.55)
    MouseArea { anchors.fill: parent; onClicked: ed.selected = "" }
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
      readonly property real cw: content.item ? content.item.width * sc : 60
      readonly property real ch: content.item ? content.item.height * sc : 40
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
        scale: px.sc
        sourceComponent: px.modelData.component
        onLoaded: { px.canVertical = "deskVertical" in item; px.feed() }
      }
      function feed() {
        var it = content.item
        if (!it) return
        if ("editing" in it) it.editing = true
        if ("deskVertical" in it) it.deskVertical = px.turnInfo.vertical
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
        onPressed: function(m) { ox = m.x; oy = m.y; ed.selected = px.wid }
        onPositionChanged: function(m) {
          if (!pressed || px.locked) return
          var p = mapToItem(null, m.x, m.y)
          var s = ed.snap(px.wid, p.x - ox + Style.space(6), p.y - oy + Style.space(6), px.width, px.height)
          px.x = s.x; px.y = s.y
          px.feed()
        }
        onReleased: {
          ed.guidesX = []; ed.guidesY = []
          if (px.locked) return
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
                  else ed.selected = ""
                }
              }
            }
          }
        }
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
        Rectangle { width: parent.width; height: 1; color: SH.HubStyle.tint(ed.fg, 0.08); visible: ed.selItem && ed.selItem.page }
        Loader {
          width: parent.width
          active: panel.visible && !!(ed.selItem && ed.selItem.page)
          sourceComponent: ed.selItem ? ed.selItem.page : null
          onLoaded: item.width = Qt.binding(function() { return width })
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
        Repeater {
          model: ed.notch ? ed.notch.deskItems : []
          delegate: SH.HubChip {
            required property var modelData
            readonly property bool onHere: ed.here.some(function(d) { return d.wid === modelData.wid })
            icon: modelData.icon
            label: modelData.title
            on: onHere
            subtle: true
            h: Style.space(28)
            fg: ed.fg; accent: ed.accent; fontFamily: ed.ff
            onClicked: {
              if (onHere) {
                if (ed.notch.placesOf(modelData.wid).length <= 1) modelData.setEnabled(false)
                ed.notch.setOnScreen(modelData.wid, ed.screenName, false)
              } else {
                if (!modelData.enabled) modelData.setEnabled(true)
                ed.notch.setOnScreen(modelData.wid, ed.screenName, true)
              }
            }
          }
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
        text: ed.ru ? "Тяните виджеты — они липнут к сетке, краям и друг к другу · клик — настройки рядом: поворот, масштаб, вид · Esc — готово"
                    : "Drag the widgets — they stick to the grid, the edges and each other · click — settings beside it: turn, scale, look · Esc — done"
        color: Qt.darker(ed.fg, 1.6)
        font.family: ed.ff; font.pixelSize: Style.font.caption - 1
      }
    }
  }

  Item {
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: if (ed.selected) ed.selected = ""; else ed.notch.editLayout(false)
  }
}
