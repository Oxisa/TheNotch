import QtQuick
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// Settings → Displays.
// Everything on one page: the monitors as a map (click to pick one), its brightness, resolution, refresh rate and scale; text size; also drag monitors on the map to arrange them (edges snap) .
Column {
  id: page
  property var mod: null
  readonly property bool full: true            // everything shown: the extra bits were too few for an Advanced mode
  spacing: SH.HubStyle.gap
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }
  readonly property var ds: mod ? mod.displays : []
  property string pick: ""
  readonly property var sel: {
    for (var i = 0; i < ds.length; i++) if (ds[i].name === pick) return ds[i]
    for (var j = 0; j < ds.length; j++) if (ds[j].focused) return ds[j]
    return ds.length ? ds[0] : null
  }
  function logical(d) { return { w: d.width / d.scale, h: d.height / d.scale } }

  component Card: SH.HubCard {
    width: page.width
    height: inner.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    default property alias content: inner.data
    Column {
      id: inner
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      spacing: Style.space(10)
    }
  }

  Text {
    visible: page.mod && !page.mod.hasBackend
    width: parent.width; wrapMode: Text.Wrap
    text: page.t("Не найден встроенный бэкенд дисплеев (vendor/display) — переустановите TheNotch.",
                 "The built-in display backend (vendor/display) is missing — reinstall TheNotch.")
    color: Color.urgent; font.family: page.ff; font.pixelSize: Style.font.caption
  }

  // ----------------------------------------------------------- the map
  Card {
    Item {
      id: map
      width: parent.width
      height: Style.space(260)
      // the bounding box of all monitors in logical pixels → fit it in
      readonly property var box: {
        var x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9
        for (var i = 0; i < page.ds.length; i++) {
          var d = page.ds[i], l = page.logical(d)
          x0 = Math.min(x0, d.x); y0 = Math.min(y0, d.y); x1 = Math.max(x1, d.x + l.w); y1 = Math.max(y1, d.y + l.h)
        }
        return page.ds.length ? { x: x0, y: y0, w: x1 - x0, h: y1 - y0 } : { x: 0, y: 0, w: 1, h: 1 }
      }
      readonly property real k: Math.min((width - Style.space(20)) / box.w, (height - Style.space(20)) / box.h)
      readonly property real ox: (width - box.w * k) / 2
      readonly property real oy: (height - box.h * k) / 2
      // the grid the monitors snap to (one line every page.grid logical px)
      Canvas {
        anchors.fill: parent
        readonly property real step: page.grid * map.k
        onStepChanged: requestPaint()
        onWidthChanged: requestPaint()
        onPaint: {
          var c = getContext("2d"); c.reset()
          if (step < 4) return
          c.strokeStyle = Qt.rgba(page.fg.r, page.fg.g, page.fg.b, 0.07); c.lineWidth = 1
          var x0 = map.ox - Math.ceil(map.ox / step) * step, y0 = map.oy - Math.ceil(map.oy / step) * step
          for (var x = x0; x < width; x += step) { c.beginPath(); c.moveTo(Math.round(x) + 0.5, 0); c.lineTo(Math.round(x) + 0.5, height); c.stroke() }
          for (var y = y0; y < height; y += step) { c.beginPath(); c.moveTo(0, Math.round(y) + 0.5); c.lineTo(width, Math.round(y) + 0.5); c.stroke() }
        }
      }
      Repeater {
        model: page.ds
        delegate: Rectangle {
          id: mon
          required property var modelData
          readonly property var l: page.logical(modelData)
          readonly property bool on: page.sel && page.sel.name === modelData.name
          x: map.ox + (modelData.x - map.box.x) * map.k
          y: map.oy + (modelData.y - map.box.y) * map.k
          width: l.w * map.k - 3; height: l.h * map.k - 3
          radius: Style.space(8)
          color: on ? SH.HubStyle.tint(page.accent, 0.30) : SH.HubStyle.tint(page.fg, 0.08)
          border.width: on ? 2 : 1
          border.color: on ? page.accent : SH.HubStyle.tint(page.fg, 0.2)
          z: dragArea.drag.active ? 5 : 1
          Column {
            anchors.centerIn: parent
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: mon.modelData.name; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.body; font.bold: true }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: mon.modelData.width + "×" + mon.modelData.height; color: Qt.darker(page.fg, 1.4); font.family: page.ff; font.pixelSize: Style.font.caption - 2 }
          }
          MouseArea {
            id: dragArea
            anchors.fill: parent
            cursorShape: page.full ? Qt.OpenHandCursor : Qt.PointingHandCursor
            drag.target: page.full ? mon : null
            onPressed: page.pick = mon.modelData.name
            onReleased: if (page.full && drag.active !== undefined) page.place(mon)
          }
        }
      }
    }
    Text {
      text: page.full ? page.t("Перетащите монитор — он пристыкуется к краю соседа и прилипнет к сетке или выравниванию", "Drag a monitor — it docks onto a neighbour's edge and snaps to the grid or an alignment")
                          : page.t("Нажмите на монитор, чтобы настроить его", "Click a monitor to set it up")
      color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption - 1
    }
  }
  // Hyprland moves the pointer across only where two monitors share an
  // edge: a dropped monitor always docks onto the nearest side of another
  // one (never overlapping), slides along that side to an aligned spot
  // (tops, bottoms, centres, ends) or else to the grid; a layout that leaves
  // a monitor touching nothing is not applied.
  readonly property int grid: 128                      // logical px per grid cell
  function overlaps(a, b) { return a.x < b.x + b.w - 1 && b.x < a.x + a.w - 1 && a.y < b.y + b.h - 1 && b.y < a.y + a.h - 1 }
  function touches(a, b) {
    var near = function(p, q) { return Math.abs(p - q) <= 1 }           // fractional scales round
    var h = (near(a.x + a.w, b.x) || near(b.x + b.w, a.x)) && Math.min(a.y + a.h, b.y + b.h) - Math.max(a.y, b.y) >= grid - 1
    var v = (near(a.y + a.h, b.y) || near(b.y + b.h, a.y)) && Math.min(a.x + a.w, b.x + b.w) - Math.max(a.x, b.x) >= grid - 1
    return h || v
  }
  function slide(want, lo, hi, aligned) {
    for (var i = 0; i < aligned.length; i++) if (aligned[i] >= lo && aligned[i] <= hi && Math.abs(want - aligned[i]) < grid / 2) return aligned[i]
    return Math.max(lo, Math.min(hi, Math.round(want / grid) * grid))
  }
  function place(item) {
    var d = item.modelData, k = map.k, l = logical(d)
    var nx = map.box.x + (item.x - map.ox) / k, ny = map.box.y + (item.y - map.oy) / k
    var rects = ds.filter(function(o) { return o.name !== d.name }).map(function(o) { var ol = logical(o); return { name: o.name, x: o.x, y: o.y, w: ol.w, h: ol.h } })
    var best = null, bestDist = 1e18, m = grid                // at least one grid cell of shared edge
    // the others together: centring over a row of monitors is an alignment too
    var ux0 = Math.min.apply(null, rects.map(function(q) { return q.x })), ux1 = Math.max.apply(null, rects.map(function(q) { return q.x + q.w }))
    var uy0 = Math.min.apply(null, rects.map(function(q) { return q.y })), uy1 = Math.max.apply(null, rects.map(function(q) { return q.y + q.h }))
    rects.forEach(function(o) {
      var ys = [o.y, o.y + o.h - l.h, Math.round(o.y + (o.h - l.h) / 2), Math.round((uy0 + uy1 - l.h) / 2)]
      var xs = [o.x, o.x + o.w - l.w, Math.round(o.x + (o.w - l.w) / 2), Math.round((ux0 + ux1 - l.w) / 2)]
      var cands = [
        { x: o.x - l.w, y: slide(ny, o.y - l.h + m, o.y + o.h - m, ys) },     // left of it
        { x: o.x + o.w, y: slide(ny, o.y - l.h + m, o.y + o.h - m, ys) },     // right of it
        { x: slide(nx, o.x - l.w + m, o.x + o.w - m, xs), y: o.y - l.h },     // above it
        { x: slide(nx, o.x - l.w + m, o.x + o.w - m, xs), y: o.y + o.h }      // below it
      ]
      cands.forEach(function(c) {
        var r = { x: c.x, y: c.y, w: l.w, h: l.h }
        if (rects.some(function(q) { return page.overlaps(r, q) })) return
        var dist = (c.x - nx) * (c.x - nx) + (c.y - ny) * (c.y - ny)
        if (dist < bestDist) { bestDist = dist; best = c }
      })
    })
    if (!best) return                                     // nowhere free: leave it where it was
    // every monitor must still touch another one (connected), or it isn't applied
    var all = rects.concat([{ name: d.name, x: best.x, y: best.y, w: l.w, h: l.h }])
    var seen = [all[0]], queue = [all[0]]
    while (queue.length) { var c = queue.shift(); all.forEach(function(q) { if (seen.indexOf(q) < 0 && page.touches(c, q)) { seen.push(q); queue.push(q) } }) }
    if (seen.length < all.length) {
      if (mod.notch) mod.notch.flash({ key: "displays", icon: "\u{f0379}", title: page.t("Так мониторы не встанут", "That layout won't work"), message: page.t("Каждый монитор должен касаться соседа краем — иначе курсор не перейдёт", "Each monitor must share an edge with another, or the pointer can't cross") })
      return
    }
    var minX = 1e9, minY = 1e9
    all.forEach(function(q) { minX = Math.min(minX, q.x); minY = Math.min(minY, q.y) })
    mod.cmd(["arrange", JSON.stringify(all.map(function(q) { return { name: q.name, x: Math.round(q.x - minX), y: Math.round(q.y - minY) } }))])
  }

  // ------------------------------------------------- the picked monitor
  Card {
    visible: page.sel !== null
    SH.HubCaption { text: page.sel ? page.sel.name + " · " + (page.sel.make + " " + page.sel.model).trim() : ""; icon: "\u{f0379}"; fg: page.fg; fontFamily: page.ff }
    SH.HubRow {
      visible: page.sel && page.mod.brightness[page.sel.name] !== undefined && page.mod.brightness[page.sel.name] >= 0
      title: page.t("Яркость", "Brightness"); fg: page.fg; fontFamily: page.ff
      SH.HubSlider {
        width: Style.space(220); minimum: 1; maximum: 100; step: 1
        value: page.sel ? Number(page.mod.brightness[page.sel.name] || 50) : 50
        format: function(v) { return Math.round(v) + "%" }
        fillColor: page.accent; fontFamily: page.ff
        onReleased: function(v) { page.mod.cmd(["brightness", page.sel.name, String(Math.round(v))]) }
      }
    }
    SH.HubRow {
      title: page.t("Разрешение", "Resolution"); fg: page.fg; fontFamily: page.ff
      SH.HubSelect {
        width: Style.space(220); showLabel: false
        readonly property var sizes: {
          var out = [], m = page.sel ? page.sel.availableModes : []
          for (var i = 0; i < m.length; i++) { var s = m[i].split("@")[0]; if (out.indexOf(s) < 0) out.push(s) }
          return out
        }
        options: sizes.map(function(s) { return { value: s, label: s.replace("x", " × ") } })
        value: page.sel ? page.sel.width + "x" + page.sel.height : ""
        foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
        onChanged: function(v) {
          var m = page.sel.availableModes.filter(function(x) { return x.indexOf(v + "@") === 0 })
          m.sort(function(a, b) { return parseFloat(b.split("@")[1]) - parseFloat(a.split("@")[1]) })
          if (m.length) page.mod.cmd(["mode", page.sel.name, m[0]])
        }
      }
    }
    SH.HubRow {
      title: page.t("Частота", "Refresh rate"); fg: page.fg; fontFamily: page.ff
      SH.HubSelect {
        width: Style.space(220); showLabel: false
        readonly property string size: page.sel ? page.sel.width + "x" + page.sel.height : ""
        options: (page.sel ? page.sel.availableModes : []).filter(function(m) { return m.indexOf(size + "@") === 0 })
                 .map(function(m) { return { value: m, label: Math.round(parseFloat(m.split("@")[1])) + page.t(" Гц", " Hz") } })
        value: {
          if (!page.sel) return ""
          var best = "", diff = 1e9, ms = page.sel.availableModes
          for (var i = 0; i < ms.length; i++) if (ms[i].indexOf(size + "@") === 0) {
            var d = Math.abs(parseFloat(ms[i].split("@")[1]) - page.sel.refreshRate)
            if (d < diff) { diff = d; best = ms[i] }
          }
          return best
        }
        foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
        onChanged: function(v) { page.mod.cmd(["mode", page.sel.name, v]) }
      }
    }
    SH.HubRow {
      title: page.t("Масштаб", "Scale"); hint: page.t("Размер всего на этом мониторе", "How big everything is on this monitor"); fg: page.fg; fontFamily: page.ff
      SH.HubSelect {
        width: Style.space(220); showLabel: false
        options: [1, 1.25, 1.5, 1.6, 1.75, 2].map(function(s) { return { value: String(s), label: Math.round(s * 100) + "%" } })
        value: page.sel ? String(page.sel.scale) : "1"
        foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
        onChanged: function(v) { page.mod.cmd(["scale", page.sel.name, v]) }
      }
    }
    Text {
      visible: !!(page.mod && page.mod.error)
      width: parent.width; wrapMode: Text.Wrap
      text: page.mod ? page.mod.error : ""
      color: Color.urgent; font.family: page.ff; font.pixelSize: Style.font.caption
    }
  }

  // ----------------------------------------------------------- text
  Card {
    SH.HubRow {
      title: page.t("Размер текста", "Text size")
      hint: page.t("Везде сразу: оболочка, приложения GTK и терминал", "Everywhere at once: the shell, GTK apps and the terminal")
      fg: page.fg; fontFamily: page.ff
      SH.HubSlider {
        width: Style.space(220); minimum: 9; maximum: 20; step: 1
        value: page.mod ? page.mod.textSize : 12
        format: function(v) { return Math.round(v) + " px" + (Math.round(v) === 12 ? page.t(" (обычный)", " (default)") : "") }
        fillColor: page.accent; fontFamily: page.ff
        onReleased: function(v) { page.mod.cmd(["text", String(Math.round(v))]) }
      }
    }
  }
}
