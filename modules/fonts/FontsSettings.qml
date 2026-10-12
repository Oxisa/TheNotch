import QtQuick
import qs.Commons
import "../../fonts"
import "../../vendor/soundhub" as SH

// Settings → Personalisation → Fonts: the same choice twice — for the
// interface and for the desktop widgets. Each preset is a card with a live
// sample; "Other" lists every installed family.
Column {
  id: page
  property var mod: null
  spacing: SH.HubStyle.gap
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }
  readonly property var fams: mod ? mod.families : []
  readonly property var presets: [
    { family: "", name: page.t("Системный", "System"), hint: Style.resolvedFontFamily + page.t(" · omarchy font set", " · omarchy font set") },
    { family: "TheNotch Goetia", name: page.t("Гоэтия", "Goetia"), hint: page.t("готика + Noto Serif, как у цитат", "blackletter + Noto Serif, like the quotes") },
    { family: "Deutsch Gothic", name: "Deutsch Gothic", hint: page.t("эксперимент: готика и для кириллицы", "experimental: blackletter for Cyrillic too"), experimental: true }
  ]
  readonly property string sample: page.t("Понедельник, 12 октября · Monday 21:45", "Monday, 12 October · Понедельник 21:45")

  component Target: SH.HubCard {
    id: tg
    property string target: "ui"
    property string title: ""
    property string hint: ""
    readonly property string current: page.mod && page.mod.notch ? String(page.mod.notch.opt(target === "ui" ? "fontUi" : "fontDesk", "")) : ""
    readonly property bool custom: current !== "" && page.presets.every(function(p) { return p.family !== current })
    width: page.width
    height: col.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    Column {
      id: col
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      spacing: Style.space(10)
      SH.HubCaption { text: tg.title; icon: tg.target === "ui" ? "\u{f0379}" : "\u{f0a1a}"; fg: page.fg; fontFamily: page.ff }
      Text { width: parent.width; wrapMode: Text.Wrap; text: tg.hint; color: Qt.darker(page.fg, 1.5); font.family: page.ff; font.pixelSize: Style.font.caption - 1 }
      Row {
        width: parent.width
        spacing: Style.space(8)
        Repeater {
          model: page.presets
          delegate: Rectangle {
            id: card
            required property var modelData
            readonly property bool installed: !modelData.family || modelData.family === "TheNotch Goetia" || page.fams.indexOf(modelData.family) >= 0
            readonly property bool on: tg.current === modelData.family
            width: (parent.width - Style.space(16)) / 3; height: Style.space(104)
            radius: SH.HubStyle.radius
            color: SH.HubStyle.tint(page.fg, cm.containsMouse ? 0.09 : 0.05)
            border.width: on ? 2 : 0; border.color: page.accent
            opacity: installed ? 1 : 0.5
            Column {
              x: Style.space(10); y: Style.space(10)
              width: parent.width - Style.space(20)
              spacing: Style.space(4)
              Text {
                width: parent.width; height: Style.space(48); wrapMode: Text.Wrap; elide: Text.ElideRight; maximumLineCount: 2
                text: page.sample
                color: page.fg; font.family: card.modelData.family || Style.font.family; font.pixelSize: Style.font.body + 1
              }
              Row {
                spacing: Style.space(6)
                Text { text: card.modelData.name; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption; font.bold: true }
                Rectangle {
                  visible: !!card.modelData.experimental
                  anchors.verticalCenter: parent.verticalCenter
                  width: ex.implicitWidth + Style.space(10); height: Style.space(16); radius: height / 2
                  color: SH.HubStyle.tint(page.accent, 0.25)
                  Text { id: ex; anchors.centerIn: parent; text: page.t("эксперимент", "experimental"); color: page.accent; font.family: page.ff; font.pixelSize: Style.font.caption - 3 }
                }
              }
              Text { width: parent.width; elide: Text.ElideRight; text: card.installed ? card.modelData.hint : page.t("не установлен — «Добавить шрифт…»", "not installed — “Add a font…”"); color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption - 2 }
            }
            MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; enabled: card.installed; onClicked: page.mod.choose(tg.target, card.modelData.family) }
          }
        }
      }
      SH.HubRow {
        width: parent.width
        title: page.t("Другой шрифт", "Another font"); hint: tg.custom ? tg.current : page.t("Любой установленный", "Any installed one")
        fg: page.fg; fontFamily: page.ff
        SH.HubSelect {
          width: Style.space(220); showLabel: false
          options: [{ value: "", label: "—" }].concat(page.fams.map(function(f) { return { value: f, label: f } }))
          value: tg.custom ? tg.current : ""
          foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
          onChanged: function(v) { if (v) page.mod.choose(tg.target, v) }
        }
      }
    }
  }

  Target { target: "desk"; title: page.t("Виджеты", "Widgets"); hint: page.t("Часы, погода, цитаты, кольца и свои виджеты на рабочем столе", "The clock, weather, quotes, rings and your own desktop widgets") }
  Target { target: "ui"; title: page.t("Интерфейс", "Interface"); hint: page.t("Чёлка и окно настроек. Иконки остаются из системного шрифта", "The notch and the settings window. Icons keep coming from the system font") }
  Row {
    spacing: Style.space(10)
    SH.HubChip {
      icon: page.mod && page.mod.busy === "install" ? "\u{f0450}" : "\u{f0415}"
      label: page.t("Добавить шрифт…", "Add a font…")
      fg: page.fg; accent: page.accent; fontFamily: page.ff
      onClicked: page.mod.addFiles()
    }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: page.t(".ttf, .otf или .zip — ставится только для вас; после нового шрифта оболочка перезапустится", ".ttf, .otf or .zip — installed for you only; the shell restarts after a new font")
      color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption - 1
    }
  }
}
