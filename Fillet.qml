import QtQuick

// The concave corner where the island meets the screen edge, so it looks
// carved out of the bezel rather than pasted on. `flip` for a bottom edge.
// Shape adapted from skuthus/omanotch (MIT).
Canvas {
  id: root
  property bool mirrored: false
  property bool flip: false
  property color fill: "black"
  width: 12
  height: 12
  antialiasing: true
  onFillChanged: requestPaint()
  onMirroredChanged: requestPaint()
  onFlipChanged: requestPaint()
  onPaint: {
    var ctx = getContext("2d")
    ctx.reset()
    ctx.save()
    if (flip) { ctx.translate(0, height); ctx.scale(1, -1) }
    ctx.fillStyle = root.fill
    ctx.beginPath()
    if (!root.mirrored) {
      ctx.moveTo(0, 0); ctx.lineTo(width, 0); ctx.lineTo(width, height)
      ctx.arc(0, height, width, 0, -Math.PI / 2, true)
    } else {
      ctx.moveTo(width, 0); ctx.lineTo(0, 0); ctx.lineTo(0, height)
      ctx.arc(width, height, width, Math.PI, 1.5 * Math.PI, false)
    }
    ctx.closePath()
    ctx.fill()
    ctx.restore()
  }
}
