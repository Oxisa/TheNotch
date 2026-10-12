import QtQuick
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// A keyboard drawn on screen for the key bindings: pick the modifiers on top
// (SUPER by default); keys that do something with them light up, hovering
// one shows what, clicking it filters the list below. After Visual
// Keybindings / Shortkeyz — the idea, not their code.
Column {
  id: kb
  property var binds: []
  property var mods: ["SUPER"]
  property string hovered: ""
  signal pick(string combo)
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property string ff: Fonts.ui
  spacing: Style.space(8)
  readonly property real unit: Math.floor((width - Style.space(4) * 14) / 15)

  function same(a, b) { return a.length === b.length && a.every(function(x) { return b.indexOf(x) >= 0 }) }
  function bindFor(key) {
    for (var i = 0; i < binds.length; i++) if (binds[i].key === key && same(binds[i].mods, mods)) return binds[i]
    return null
  }
  readonly property var rows: [
    [["ESCAPE", "Esc"], ["F1"], ["F2"], ["F3"], ["F4"], ["F5"], ["F6"], ["F7"], ["F8"], ["F9"], ["F10"], ["F11"], ["F12"], ["PRINT", "Prt", 1.5]],
    [["GRAVE", "`"], ["1"], ["2"], ["3"], ["4"], ["5"], ["6"], ["7"], ["8"], ["9"], ["0"], ["MINUS", "-"], ["EQUAL", "="], ["BACKSPACE", "⌫", 1.5]],
    [["TAB", "Tab", 1.5], ["Q"], ["W"], ["E"], ["R"], ["T"], ["Y"], ["U"], ["I"], ["O"], ["P"], ["BRACKETLEFT", "["], ["BRACKETRIGHT", "]"], ["BACKSLASH", "\\", 1]],
    [["CAPS", "Caps", 1.75], ["A"], ["S"], ["D"], ["F"], ["G"], ["H"], ["J"], ["K"], ["L"], ["SEMICOLON", ";"], ["APOSTROPHE", "'"], ["RETURN", "Enter", 1.75]],
    [["SHIFT_L", "Shift", 2.25], ["Z"], ["X"], ["C"], ["V"], ["B"], ["N"], ["M"], ["COMMA", ","], ["PERIOD", "."], ["SLASH", "/"], ["UP", "↑"], ["DELETE", "Del", 1.25]],
    [["CTRL", "Ctrl", 1.5], ["ALT_L", "Alt", 1.25], ["SUPER", "Super", 1.25], ["SPACE", "", 5.5], ["HOME", "Home"], ["LEFT", "←"], ["DOWN", "↓"], ["RIGHT", "→"]]
  ]

  Row {
    spacing: Style.space(6)
    Text { anchors.verticalCenter: parent.verticalCenter; text: kb.mods.length ? "" : ""; width: 0 }
    Repeater {
      model: ["SUPER", "CTRL", "ALT", "SHIFT"]
      delegate: SH.HubChip {
        required property string modelData
        label: modelData
        on: kb.mods.indexOf(modelData) >= 0
        subtle: true
        h: Style.space(26)
        fg: kb.fg; accent: kb.accent; fontFamily: kb.ff
        onClicked: {
          var m = kb.mods.slice()
          if (on) m = m.filter(function(x) { return x !== modelData }); else m.push(modelData)
          kb.mods = ["SUPER", "CTRL", "ALT", "SHIFT"].filter(function(x) { return m.indexOf(x) >= 0 })
        }
      }
    }
  }
  Repeater {
    model: kb.rows
    delegate: Row {
      required property var modelData
      spacing: Style.space(4)
      Repeater {
        model: modelData
        delegate: Rectangle {
          id: key
          required property var modelData
          readonly property string code: modelData[0]
          readonly property var bind: kb.bindFor(code)
          readonly property bool held: ["CTRL", "ALT_L", "SUPER", "SHIFT_L"].indexOf(code) >= 0
                                       && kb.mods.indexOf(code.replace("_L", "")) >= 0
          width: kb.unit * (modelData[2] || 1) + Style.space(4) * ((modelData[2] || 1) - 1)
          height: kb.unit * 0.9
          radius: Style.space(6)
          color: held ? kb.accent : bind ? SH.HubStyle.tint(kb.accent, km.containsMouse ? 0.55 : 0.32)
                                         : SH.HubStyle.tint(kb.fg, km.containsMouse ? 0.12 : 0.06)
          border.width: 1; border.color: SH.HubStyle.tint(kb.fg, 0.08)
          Text {
            anchors.centerIn: parent
            text: key.modelData.length > 1 ? key.modelData[1] : key.code
            color: key.held ? Color.background : kb.fg
            font.family: kb.ff; font.pixelSize: Math.max(9, kb.unit * 0.3); font.bold: !!key.bind
          }
          MouseArea {
            id: km
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: key.bind ? Qt.PointingHandCursor : Qt.ArrowCursor
            onContainsMouseChanged: kb.hovered = containsMouse ? (key.bind ? key.bind.keys + " — " + key.bind.what : key.code) : ""
            onClicked: if (key.bind) kb.pick(key.bind.keys)
          }
        }
      }
    }
  }
  Text {
    width: parent.width; elide: Text.ElideRight
    text: kb.hovered || (kb.mods.length ? kb.mods.join(" + ") + " + …" : "")
    color: kb.hovered ? kb.fg : Qt.darker(kb.fg, 1.6)
    font.family: kb.ff; font.pixelSize: Style.font.caption
  }
}
