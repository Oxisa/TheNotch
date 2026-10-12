import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// Settings → About, like fastfetch in a window: Omarchy's logo on the left
// in the accent colour, user@host and the facts on the right, then memory
// and disks as bars and the theme's palette. Copy puts it all as text.
Column {
  id: page
  property var mod: null
  spacing: SH.HubStyle.gap
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }
  Component.onCompleted: if (mod) mod.load()
  readonly property var i: mod ? mod.info : ({})
  FileView { id: logo; path: "/usr/share/omarchy/icon.txt"; printErrors: false }

  function uptime(s) {
    var d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60)
    return (d ? d + page.t(" дн ", " d ") : "") + h + page.t(" ч ", " h ") + m + page.t(" мин", " min")
  }
  readonly property var rows: !i.host ? [] : [
    { icon: "\u{f08c7}", k: "OS", v: (i.os || "") + " " + (i.omarchy || "") + (i.channel ? " · " + i.channel : "") },
    { icon: "\u{f0a0c}", k: page.t("Ядро", "Kernel"), v: i.kernel },
    { icon: "\u{f05b4}", k: "WM", v: i.wm },
    { icon: "\u{f03d8}", k: page.t("Тема", "Theme"), v: i.theme },
    { icon: "\u{f03d6}", k: page.t("Пакеты", "Packages"), v: String(i.packages) + " (pacman)" },
    { icon: "\u{f0954}", k: page.t("Работает", "Uptime"), v: page.uptime(i.uptime || 0) },
    { icon: "\u{f0ee0}", k: page.t("Процессор", "CPU"), v: i.cpu ? i.cpu.name + " · " + i.cpu.cores + page.t(" ядер / ", " cores / ") + i.cpu.threads + page.t(" потоков · до ", " threads · up to ") + i.cpu.ghz + page.t(" ГГц", " GHz") : "" },
    { icon: "\u{f08ae}", k: page.t("Видеокарта", "GPU"), v: (i.gpus || []).map(function(g) { return g.vendor + " " + g.name + (g.type === "Integrated" ? page.t(" (встроенная)", " (integrated)") : "") }).join("\n") },
    { icon: "\u{f0379}", k: page.t("Мониторы", "Displays"), v: (i.displays || []).map(function(d) { return d.w + "×" + d.h + " @ " + d.hz + page.t(" Гц", " Hz") }).join(", ") },
    { icon: "\u{f061a}", k: page.t("Плата", "Board"), v: i.board }
  ]

  SH.HubCard {
    width: page.width
    height: Math.max(logoText.implicitHeight, facts.implicitHeight) + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    Text {
      id: logoText
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      text: logo.text()
      color: page.accent
      font.family: "monospace"; font.pixelSize: Math.max(4, Math.round(Style.space(6)))
      lineHeight: 1.0
    }
    Column {
      id: facts
      anchors.left: logoText.right; anchors.leftMargin: Style.space(26)
      anchors.right: parent.right; anchors.rightMargin: SH.HubStyle.pad
      y: SH.HubStyle.pad
      spacing: Style.space(5)
      Text {
        text: (page.i.user || "") + "@" + (page.i.host || "")
        color: page.accent; font.family: page.ff; font.pixelSize: Style.font.body + 6; font.bold: true
      }
      Rectangle { width: parent.width; height: 1; color: SH.HubStyle.tint(page.fg, 0.12) }
      Repeater {
        model: page.rows
        delegate: Row {
          required property var modelData
          visible: !!modelData.v
          width: facts.width
          spacing: Style.space(8)
          Text { width: Style.space(18); text: modelData.icon; color: page.accent; font.family: page.ff; font.pixelSize: Style.font.body }
          Text { width: Style.space(96); text: modelData.k; color: page.accent; font.family: page.ff; font.pixelSize: Style.font.caption + 1; font.bold: true }
          Text { width: parent.width - Style.space(130); wrapMode: Text.Wrap; text: modelData.v; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption + 1 }
        }
      }
      Row {
        spacing: Style.space(4)
        topPadding: Style.space(6)
        Repeater {
          model: page.i.palette || []
          delegate: Rectangle { required property string modelData; width: Style.space(22); height: Style.space(14); radius: Style.space(3); color: modelData }
        }
      }
    }
  }

  // memory and disks
  component Bar: Column {
    property string label: ""
    property real used: 0
    property real total: 1
    width: page.width
    spacing: Style.space(4)
    Item {
      width: parent.width; height: Style.space(18)
      Text { text: parent.parent.label; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption + 1 }
      Text { anchors.right: parent.right; text: parent.parent.used + page.t(" из ", " of ") + parent.parent.total + page.t(" ГБ", " GB") + "  ·  " + Math.round(parent.parent.used / Math.max(0.1, parent.parent.total) * 100) + "%"; color: Qt.darker(page.fg, 1.4); font.family: page.ff; font.pixelSize: Style.font.caption }
    }
    Rectangle {
      width: parent.width; height: Style.space(8); radius: height / 2
      color: SH.HubStyle.tint(page.fg, 0.1)
      Rectangle { width: parent.width * Math.min(1, parent.parent.used / Math.max(0.1, parent.parent.total)); height: parent.height; radius: height / 2; color: page.accent }
    }
  }
  SH.HubCard {
    width: page.width
    height: bars.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    Column {
      id: bars
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      spacing: Style.space(12)
      Bar { width: parent.width; label: "\u{f035b}  " + page.t("Память", "Memory"); used: page.i.memory ? page.i.memory.used : 0; total: page.i.memory ? page.i.memory.total : 1 }
      Repeater {
        model: page.i.disks || []
        delegate: Bar {
          required property var modelData
          width: bars.width
          label: "\u{f02ca}  " + (modelData.mount === "/" ? page.t("Системный диск", "System disk") : modelData.mount.split("/").pop()) + "  ·  " + modelData.fs
          used: modelData.used; total: modelData.total
        }
      }
    }
  }

  Row {
    spacing: Style.space(8)
    SH.HubChip {
      property bool done: false
      icon: done ? "\u{f012c}" : "\u{f018f}"
      label: done ? page.t("Скопировано", "Copied") : page.t("Скопировать сведения", "Copy the details")
      fg: page.fg; accent: page.accent; fontFamily: page.ff
      onClicked: {
        var s = [(page.i.user || "") + "@" + (page.i.host || "")]
        page.rows.forEach(function(r) { if (r.v) s.push(r.k + ": " + String(r.v).replace(/\n/g, ", ")) })
        if (page.i.memory) s.push(page.t("Память", "Memory") + ": " + page.i.memory.used + " / " + page.i.memory.total + " GB")
        Quickshell.execDetached(["wl-copy", s.join("\n")]); done = true
      }
    }
    SH.HubChip {
      icon: "\u{f018d}"; label: page.t("fastfetch в терминале", "fastfetch in a terminal")
      fg: page.fg; accent: page.accent; fontFamily: page.ff
      onClicked: Quickshell.execDetached(["omarchy-launch-floating-terminal-with-presentation", "fastfetch"])
    }
  }
}
