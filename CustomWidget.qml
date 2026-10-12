import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Commons
import "DeskStyle.js" as DS
import "fonts"

// Your own desktop widget, made in the layout editor:
//   text     a template — {time} {date} {day} {user} {host} {weather} {temp}
//            {cpu} {ram} — refreshed every second
//   command  a shell command's output, refreshed every N seconds
//   image    a picture
//   note     your own text
// It wears the shared Style (DeskStyle.js) like every other widget.
Rectangle {
  id: cw
  property var notch: null
  property string deskId: ""
  property var deskStyle: ({})
  property bool editing: false
  readonly property bool deskShown: true
  readonly property var def: notch && deskId ? notch.customById(deskId.replace(/^custom:/, "")) : null
  readonly property string type: def ? def.type : "text"
  readonly property var cfg: def && def.cfg ? def.cfg : ({})
  readonly property color fg: DS.fg(deskStyle, Color.foreground)
  readonly property color accent: DS.accent(deskStyle, Color.accent)
  readonly property string ff: cfg.font === "gothic" ? gothic.name : cfg.font === "serif" ? "Noto Serif" : Fonts.desk
  FontLoader { id: gothic; source: Qt.resolvedUrl("vendor/dailyquote/fonts/UnifrakturMaguntia-Book.ttf") }

  readonly property real pad: type === "image" ? Style.space(8) : Style.space(18)
  width: Math.max(Style.space(60), body.width + pad * 2)
  height: Math.max(Style.space(40), body.height + pad * 2)
  radius: DS.radius(deskStyle, Style.space(18))
  topLeftRadius: DS.corner(deskStyle, "tl", Style.space(18))
  topRightRadius: DS.corner(deskStyle, "tr", Style.space(18))
  bottomLeftRadius: DS.corner(deskStyle, "bl", Style.space(18))
  bottomRightRadius: DS.corner(deskStyle, "br", Style.space(18))
  color: DS.bg(deskStyle, Color.background, accent, 0.85)
  border.width: 1
  border.color: DS.border(deskStyle, Color.foreground)

  // ------------------------------------------------------------- text
  property date now: new Date()
  Timer { interval: 1000; repeat: true; running: cw.type === "text"; triggeredOnStart: true; onTriggered: cw.now = new Date() }
  function fill(t) {
    var w = notch ? notch.moduleById("weather") : null, s = notch ? notch.moduleById("system") : null, d = s ? s.data : {}
    var ru = notch && notch.lang === "ru", loc = Qt.locale(ru ? "ru_RU" : "en_US")
    var map = {
      time: Qt.formatTime(now, "HH:mm"), date: now.toLocaleDateString(loc, "d MMMM"), day: now.toLocaleDateString(loc, "dddd"),
      user: Quickshell.env("USER") || "", host: Quickshell.env("HOSTNAME") || "",
      weather: w && w.now ? w.glyph(w.now.code, w.now.day) + " " + w.deg(w.now.temp) : "", temp: w && w.now ? w.deg(w.now.temp) : "",
      cpu: d.cpu !== undefined ? Math.round(d.cpu) + "%" : "", ram: d.ramTotal ? Math.round(d.ramUsed / d.ramTotal * 100) + "%" : ""
    }
    return String(t || "").replace(/\\n/g, "\n").replace(/\{(\w+)\}/g, function(m, k) { return map[k] !== undefined ? map[k] : m })
  }

  // ---------------------------------------------------------- command
  property string output: ""
  Process {
    id: proc
    command: ["bash", "-c", String(cw.cfg.command || "")]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: cw.output = text.replace(/\s+$/, "") }
  }
  Timer {
    interval: Math.max(1, Number(cw.cfg.interval || 30)) * 1000
    repeat: true; triggeredOnStart: true
    running: cw.type === "command" && !!cw.cfg.command
    onTriggered: if (!proc.running) proc.running = true
  }

  Item {
    id: body
    anchors.centerIn: parent
    width: cw.type === "image" ? pic.width : label.implicitWidth
    height: cw.type === "image" ? pic.height : label.implicitHeight
    Text {
      id: label
      visible: cw.type !== "image"
      text: cw.type === "text" ? cw.fill(cw.cfg.template) : cw.type === "command" ? (cw.output || "…") : String(cw.cfg.text || "")
      color: cw.fg
      horizontalAlignment: cw.cfg.align === "left" ? Text.AlignLeft : cw.cfg.align === "right" ? Text.AlignRight : Text.AlignHCenter
      font.family: cw.type === "command" ? "monospace" : cw.ff
      font.pixelSize: Number(cw.cfg.size || 16)
      font.bold: cw.cfg.bold === true
      wrapMode: Text.NoWrap
    }
    ClippingRectangle {
      id: pic
      visible: cw.type === "image"
      width: Number(cw.cfg.width || 260)
      height: img.status === Image.Ready && img.implicitWidth ? width * img.implicitHeight / img.implicitWidth : width * 0.6
      radius: Number(cw.cfg.radius || 0)
      color: "transparent"
      Image { id: img; anchors.fill: parent; source: cw.cfg.path ? "file://" + cw.cfg.path : ""; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 800 }
      Text { visible: !cw.cfg.path; anchors.centerIn: parent; text: "\u{f02e9}"; color: cw.fg; font.family: Fonts.desk; font.pixelSize: Style.space(36) }
    }
  }
}
