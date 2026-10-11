import QtQuick
import qs.Commons
import "../../../osia.soundhub" as SH

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
  readonly property string ff: Style.font.family
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
    text: page.t("Нужен плагин Display Settings (omarchy-display) — включите его в «Плагинах Omarchy».",
                 "Needs the Display Settings plugin (omarchy-display) — turn it on in Omarchy plugins.")
    color: Color.urgent; font.family: page.ff; font.pixelSize: Style.font.caption
  }

  // ----------------------------------------------------------- the map
  Card {
    Item {
      id: map
      width: parent.width
      height: Style.space(200)
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
      text: page.full ? page.t("Перетащите монитор — края прилипают к соседям", "Drag a monitor — edges stick to the neighbours")
                          : page.t("Нажмите на монитор, чтобы настроить его", "Click a monitor to set it up")
      color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption - 1
    }
  }
  // turn the dropped rectangle back into logical positions, snap, save
  function place(item) {
    var d = item.modelData, k = map.k
    var nx = map.box.x + (item.x - map.ox) / k, ny = map.box.y + (item.y - map.oy) / k
    var l = logical(d), snap = 60
    for (var i = 0; i < ds.length; i++) {
      var o = ds[i]
      if (o.name === d.name) continue
      var ol = logical(o)
      var xs = [o.x - l.w, o.x + ol.w, o.x, o.x + ol.w - l.w], ys = [o.y - l.h, o.y + ol.h, o.y, o.y + ol.h - l.h]
      for (var a = 0; a < xs.length; a++) if (Math.abs(nx - xs[a]) < snap) { nx = xs[a]; break }
      for (var b = 0; b < ys.length; b++) if (Math.abs(ny - ys[b]) < snap) { ny = ys[b]; break }
    }
    var layout = [], minX = 1e9, minY = 1e9
    for (var j = 0; j < ds.length; j++) {
      var p = ds[j].name === d.name ? { name: d.name, x: nx, y: ny } : { name: ds[j].name, x: ds[j].x, y: ds[j].y }
      layout.push(p); minX = Math.min(minX, p.x); minY = Math.min(minY, p.y)
    }
    for (var m = 0; m < layout.length; m++) { layout[m].x = Math.round(layout[m].x - minX); layout[m].y = Math.round(layout[m].y - minY) }
    mod.cmd(["arrange", JSON.stringify(layout)])
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
