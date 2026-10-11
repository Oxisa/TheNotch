import QtQuick
import qs.Commons
import "../../../osia.soundhub" as SH

// The music spectrum as a desktop widget, from SoundHub's one shared cava
// capture (no second audio tap). Three looks:
//   bars    tall bars with peak dots that fall slowly
//   led     a dot matrix, lit from the bottom like a rack equalizer
//   pulse   a ring of rays around a disc that breathes with the bass
// Looks after rover-001/whimsy's visualizers (MIT); no code taken.
Rectangle {
  id: v
  property var mod: null
  property bool editing: false
  readonly property bool deskShown: true
  readonly property string look: mod ? String(mod.opt("vizLook", "bars")) : "bars"
  readonly property var levels: mod && mod.cava && mod.cava.levels ? mod.cava.levels : []
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent

  width: look === "pulse" ? Style.space(220) : Style.space(360)
  height: look === "pulse" ? Style.space(220) : Style.space(150)
  radius: SH.HubStyle.radius + Style.space(4)
  readonly property color bgc: Color.background
  color: Qt.rgba(bgc.r, bgc.g, bgc.b, mod ? Number(mod.opt("vizOpacity", 0.6)) : 0.6)
  border.width: 1
  border.color: SH.HubStyle.tint(fg, 0.08)

  // falling peaks for "bars"
  property var peaks: []
  onLevelsChanged: {
    var p = peaks.slice(), l = levels
    for (var i = 0; i < l.length; i++) p[i] = Math.max(l[i], (p[i] || 0) - 0.012)
    peaks = p
    canvas.requestPaint()
  }

  Canvas {
    id: canvas
    anchors.fill: parent
    anchors.margins: Style.space(16)
    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      var l = v.levels, n = Math.min(24, l.length)
      if (!n) return
      var w = width, h = height
      if (v.look === "bars") {
        var gap = 4, bw = (w - gap * (n - 1)) / n
        for (var i = 0; i < n; i++) {
          var x = i * (bw + gap), lv = Math.max(0.02, l[i]), bh = lv * h
          var g = ctx.createLinearGradient(0, h, 0, h - bh)
          g.addColorStop(0, Qt.rgba(v.accent.r, v.accent.g, v.accent.b, 0.55))
          g.addColorStop(1, v.accent)
          ctx.fillStyle = g
          ctx.beginPath(); ctx.roundedRect(x, h - bh, bw, bh, bw / 3, bw / 3); ctx.fill()
          var pk = (v.peaks[i] || 0) * h
          ctx.fillStyle = v.fg
          ctx.beginPath(); ctx.roundedRect(x, h - pk - 5, bw, 3, 1.5, 1.5); ctx.fill()
        }
      } else if (v.look === "led") {
        var rows = 10, cols = n, cw = w / cols, rh = h / rows, r = Math.min(cw, rh) * 0.32
        for (var c = 0; c < cols; c++) {
          var lit = Math.round(l[c] * rows)
          for (var rr = 0; rr < rows; rr++) {
            var on = rr < lit
            var hot = rr >= rows * 0.8
            ctx.fillStyle = on ? (hot ? Qt.tint(v.accent, Qt.rgba(1, 0.3, 0.3, 0.5)) : v.accent) : Qt.rgba(v.fg.r, v.fg.g, v.fg.b, 0.08)
            ctx.beginPath(); ctx.arc(c * cw + cw / 2, h - (rr * rh + rh / 2), r, 0, Math.PI * 2); ctx.fill()
          }
        }
      } else {                                         // pulse
        var cx = w / 2, cy = h / 2, base = Math.min(w, h) * 0.22
        var bass = (l[0] + l[1] + l[2]) / 3
        ctx.fillStyle = Qt.rgba(v.accent.r, v.accent.g, v.accent.b, 0.25 + bass * 0.5)
        ctx.beginPath(); ctx.arc(cx, cy, base * (0.8 + bass * 0.5), 0, Math.PI * 2); ctx.fill()
        ctx.strokeStyle = v.accent; ctx.lineCap = "round"; ctx.lineWidth = 3
        var rays = n * 2
        for (var k = 0; k < rays; k++) {
          var lv2 = l[k < n ? k : rays - 1 - k] || 0
          var a = -Math.PI / 2 + k * Math.PI * 2 / rays
          var r0 = base + 6, r1 = r0 + 6 + lv2 * Math.min(w, h) * 0.26
          ctx.beginPath(); ctx.moveTo(cx + Math.cos(a) * r0, cy + Math.sin(a) * r0)
          ctx.lineTo(cx + Math.cos(a) * r1, cy + Math.sin(a) * r1); ctx.stroke()
        }
      }
    }
  }
  Text {
    anchors.centerIn: parent
    visible: v.editing && v.levels.every(function(x) { return x < 0.02 })
    text: "\u{f0ea2}  " + (v.mod && v.mod.ru ? "Визуализатор" : "Visualizer")
    color: Qt.darker(v.fg, 1.5)
    font.family: Style.font.family; font.pixelSize: Style.font.body
  }
}
