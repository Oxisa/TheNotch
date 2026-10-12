import QtQuick
import Quickshell
import qs.Commons
import "vendor/soundhub" as SH
import "fonts"

// The "Look" tab for your own widget in the layout editor: its name, its
// content (a template, a command, a picture or a note), the font, and Delete.
Column {
  id: page
  property var notch: null
  spacing: Style.space(8)
  readonly property string id_: notch && notch.layoutPick ? notch.layoutPick.replace(/^custom:/, "") : ""
  readonly property var def: notch ? notch.customById(id_) : null
  readonly property var cfg: def && def.cfg ? def.cfg : ({})
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  function setCfg(v) { var c = {}; for (var k in cfg) c[k] = cfg[k]; for (var k2 in v) c[k2] = v[k2]; notch.patchCustom(id_, { cfg: c }) }

  SH.HubField {
    width: parent.width
    icon: "\u{f0284}"
    placeholderText: page.t("Название", "Name")
    text: page.def && page.def.title ? page.def.title : ""
    fg: page.fg; accent: page.accent; fontFamily: page.ff
    onEditingFinished: page.notch.patchCustom(page.id_, { title: text.trim() })
  }
  // content
  SH.HubField {
    visible: !!page.def && page.def.type === "text"
    width: parent.width
    icon: "\u{f0284}"
    placeholderText: "{time} · {date} · {weather}"
    text: page.cfg.template || ""
    fg: page.fg; accent: page.accent; fontFamily: page.ff
    onEditingFinished: page.setCfg({ template: text.replace(/\\n/g, "\n") })
  }
  Text {
    visible: !!page.def && page.def.type === "text"
    width: parent.width; wrapMode: Text.Wrap
    text: page.t("Подстановки: {time} {date} {day} {user} {weather} {temp} {cpu} {ram}; новая строка — \\n",
                 "Fields: {time} {date} {day} {user} {weather} {temp} {cpu} {ram}; a new line is \\n")
    color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption - 1
  }
  SH.HubField {
    visible: !!page.def && page.def.type === "command"
    width: parent.width
    icon: "\u{f018d}"
    placeholderText: "uptime -p"
    text: page.cfg.command || ""
    fg: page.fg; accent: page.accent; fontFamily: page.ff
    onEditingFinished: page.setCfg({ command: text })
  }
  SH.HubRow {
    visible: !!page.def && page.def.type === "command"
    title: page.t("Обновлять каждые", "Refresh every"); fg: page.fg; fontFamily: page.ff
    SH.HubSlider { width: Style.space(140); minimum: 1; maximum: 600; step: 1; value: Number(page.cfg.interval || 30)
      format: function(v) { return Math.round(v) + page.t(" с", " s") }
      fillColor: page.accent; fontFamily: page.ff; onReleased: function(v) { page.setCfg({ interval: Math.round(v) }) } }
  }
  SH.HubField {
    visible: !!page.def && page.def.type === "image"
    width: parent.width
    icon: "\u{f02e9}"
    placeholderText: page.t("Путь к картинке: ~/Pictures/…", "Picture path: ~/Pictures/…")
    text: page.cfg.path || ""
    fg: page.fg; accent: page.accent; fontFamily: page.ff
    onEditingFinished: page.setCfg({ path: text.trim().replace(/^~/, Quickshell.env("HOME")) })
  }
  SH.HubRow {
    visible: !!page.def && page.def.type === "image"
    title: page.t("Ширина", "Width"); fg: page.fg; fontFamily: page.ff
    SH.HubSlider { width: Style.space(140); minimum: 80; maximum: 800; step: 10; value: Number(page.cfg.width || 260)
      format: function(v) { return Math.round(v) + " px" }
      fillColor: page.accent; fontFamily: page.ff; onReleased: function(v) { page.setCfg({ width: Math.round(v) }) } }
  }
  SH.HubRow {
    visible: !!page.def && page.def.type === "image"
    title: page.t("Скругление картинки", "Picture corners"); fg: page.fg; fontFamily: page.ff
    SH.HubSlider { width: Style.space(140); minimum: 0; maximum: 200; step: 2; value: Number(page.cfg.radius || 0)
      format: function(v) { return Math.round(v) + " px" }
      fillColor: page.accent; fontFamily: page.ff; onReleased: function(v) { page.setCfg({ radius: Math.round(v) }) } }
  }
  SH.HubField {
    visible: !!page.def && page.def.type === "note"
    width: parent.width
    icon: "\u{f039b}"
    placeholderText: page.t("Текст заметки (\\n — новая строка)", "The note (\\n for a new line)")
    text: (page.cfg.text || "").replace(/\n/g, "\\n")
    fg: page.fg; accent: page.accent; fontFamily: page.ff
    onEditingFinished: page.setCfg({ text: text.replace(/\\n/g, "\n") })
  }
  // text look
  SH.HubRow {
    visible: !!page.def && page.def.type !== "image"
    title: page.t("Размер текста", "Text size"); fg: page.fg; fontFamily: page.ff
    SH.HubSlider { width: Style.space(140); minimum: 10; maximum: 120; step: 1; value: Number(page.cfg.size || 16)
      format: function(v) { return Math.round(v) + " px" }
      fillColor: page.accent; fontFamily: page.ff; onReleased: function(v) { page.setCfg({ size: Math.round(v) }) } }
  }
  SH.HubRow {
    visible: !!page.def && (page.def.type === "text" || page.def.type === "note")
    title: page.t("Шрифт", "Font"); fg: page.fg; fontFamily: page.ff
    SH.HubSelect {
      width: Style.space(150); showLabel: false
      options: [{ value: "theme", label: page.t("Как в теме", "Theme") }, { value: "gothic", label: page.t("Готический", "Blackletter") }, { value: "serif", label: page.t("С засечками", "Serif") }]
      value: String(page.cfg.font || "theme")
      foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
      onChanged: function(v) { page.setCfg({ font: v }) }
    }
  }
  SH.HubRow {
    visible: !!page.def && page.def.type !== "image"
    title: page.t("Жирный", "Bold"); fg: page.fg; fontFamily: page.ff
    SH.HubSwitch { checked: page.cfg.bold === true; fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.setCfg({ bold: !checked }) }
  }
  SH.HubChip {
    property int confirm: 0
    icon: "\u{f09e7}"
    label: confirm ? page.t("Нажмите ещё раз — удалить", "Click again to delete") : page.t("Удалить виджет", "Delete the widget")
    fg: page.fg; accent: page.accent; fontFamily: page.ff
    onClicked: { if (++confirm >= 2) { page.notch.layoutPick = ""; page.notch.removeCustom(page.id_) } else resetDel.restart() }
    Timer { id: resetDel; interval: 3000; onTriggered: parent.confirm = 0 }
  }
}
