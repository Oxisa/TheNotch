import QtQuick
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../DeskStyle.js" as DS
import "../../fonts"

// The music spectrum as a desktop widget, from SoundHub's one shared cava
// capture (no second audio tap). Three looks:
//   bars    tall bars with peak dots that fall slowly
//   led     a dot matrix, lit from the bottom like a rack equalizer
//   pulse   a ring of rays around a disc that breathes with the bass
// Looks after rover-001/whimsy's visualizers (MIT); no code taken. Drawn
// with scene-graph items so the GPU does the work.
Rectangle {
  id: v
  property var mod: null
  property bool editing: false
  readonly property bool deskShown: true
  readonly property string look: mod ? String(mod.opt("vizLook", "bars")) : "bars"
  readonly property var levels: mod && mod.cava && mod.cava.levels ? mod.cava.levels : []
  property var deskStyle: ({})
  readonly property color fg: DS.fg(deskStyle, Color.foreground)
  readonly property color accent: DS.accent(deskStyle, Color.accent)

  width: look === "pulse" ? Style.space(220) : Style.space(360)
  height: look === "pulse" ? Style.space(220) : Style.space(150)
  radius: DS.radius(deskStyle, SH.HubStyle.radius + Style.space(4))
  topLeftRadius: DS.corner(deskStyle, "tl", SH.HubStyle.radius + Style.space(4))
  topRightRadius: DS.corner(deskStyle, "tr", SH.HubStyle.radius + Style.space(4))
  bottomLeftRadius: DS.corner(deskStyle, "bl", SH.HubStyle.radius + Style.space(4))
  bottomRightRadius: DS.corner(deskStyle, "br", SH.HubStyle.radius + Style.space(4))
  readonly property color bgc: Color.background
  color: DS.bg(deskStyle, bgc, accent, mod ? Number(mod.opt("vizOpacity", 0.6)) : 0.6)
  border.width: 1
  border.color: DS.border(deskStyle, Color.foreground)

  // Drawn with scene-graph items, not a Canvas: the levels only move
  // heights and opacities (the GPU does the rest) — a Canvas repainting 24
  // gradients 40 times a second cost ~9 % of a core.
  readonly property int n: Math.min(24, levels.length || 24)
  function lv(i) { return Math.max(0, Math.min(1, levels[i] || 0)) }

  Item {
    id: area
    anchors.fill: parent
    anchors.margins: Style.space(16)

    // ---- bars, with peak marks that fall slowly
    Row {
      visible: v.look === "bars"
      width: area.width; height: area.height
      spacing: 4
      Repeater {
        model: v.n
        delegate: Item {
          id: bar
          required property int index
          readonly property real level: Math.max(0.02, v.lv(index))
          property real peak: 0
          onLevelChanged: peak = Math.max(level, peak - 0.012)
          width: (area.width - 4 * (v.n - 1)) / v.n; height: area.height
          Rectangle {
            y: bar.height - height
            width: bar.width; height: bar.level * bar.height
            radius: width / 3
            gradient: Gradient {
              GradientStop { position: 0; color: v.accent }
              GradientStop { position: 1; color: Qt.rgba(v.accent.r, v.accent.g, v.accent.b, 0.55) }
            }
          }
          Rectangle { y: bar.height - bar.peak * bar.height - 5; width: bar.width; height: 3; radius: 1.5; color: v.fg }
        }
      }
    }

    // ---- LED matrix, lit from the bottom
    Row {
      visible: v.look === "led"
      Repeater {
        model: v.look === "led" ? v.n : 0
        delegate: Column {
          id: col
          required property int index
          readonly property int lit: Math.round(v.lv(index) * 10)
          width: area.width / v.n
          Repeater {
            model: 10
            delegate: Item {
              required property int index
              readonly property int row: 9 - index                   // 0 = bottom
              width: col.width; height: area.height / 10
              Rectangle {
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height) * 0.64; height: width; radius: width / 2
                color: parent.row < col.lit ? (parent.row >= 8 ? Qt.tint(v.accent, Qt.rgba(1, 0.3, 0.3, 0.5)) : v.accent) : Qt.rgba(v.fg.r, v.fg.g, v.fg.b, 0.08)
              }
            }
          }
        }
      }
    }

    // ---- pulse: a disc that breathes with the bass, rays around it
    Item {
      visible: v.look === "pulse"
      anchors.fill: parent
      readonly property real base: Math.min(width, height) * 0.22
      readonly property real bass: (v.lv(0) + v.lv(1) + v.lv(2)) / 3
      Rectangle {
        anchors.centerIn: parent
        width: parent.base * 2 * (0.8 + parent.bass * 0.5); height: width; radius: width / 2
        color: Qt.rgba(v.accent.r, v.accent.g, v.accent.b, 0.25 + parent.bass * 0.5)
      }
      Repeater {
        model: v.look === "pulse" ? v.n * 2 : 0
        delegate: Rectangle {
          required property int index
          readonly property real level: v.lv(index < v.n ? index : v.n * 2 - 1 - index)
          readonly property real r0: parent.base + 6
          readonly property real len: 6 + level * Math.min(parent.width, parent.height) * 0.26
          // a ray standing on the disc's edge, turned around the centre
          x: parent.width / 2 - width / 2; y: parent.height / 2 - r0 - len
          width: 3; height: len; radius: 1.5
          color: v.accent
          transform: Rotation { origin.x: 1.5; origin.y: r0 + len; angle: index * 360 / (v.n * 2) }
        }
      }
    }
  }
  Text {
    anchors.centerIn: parent
    visible: v.editing && v.levels.every(function(x) { return x < 0.02 })
    text: "\u{f0ea2}  " + (v.mod && v.mod.ru ? "Визуализатор" : "Visualizer")
    color: Qt.darker(v.fg, 1.5)
    font.family: Fonts.desk; font.pixelSize: Style.font.body
  }
}
