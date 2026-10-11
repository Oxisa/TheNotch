import QtQuick
import qs.Commons
import "../../../osia.soundhub" as SH

// The clock's card in Settings → Widgets.
Column {
  id: page
  property var mod: null
  spacing: Style.space(10)

  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Style.font.family
  readonly property bool ru: mod && mod.ru
  readonly property var cfg: mod ? mod.cfg : ({})
  function set(key, value) { var v = {}; v[key] = value; mod.persist(v) }

  component Sw: SH.HubRow {
    id: sw
    property string key: ""
    fg: page.fg; fontFamily: page.ff
    SH.HubSwitch {
      checked: page.cfg[sw.key] === true
      fg: page.fg; accent: page.accent; ink: page.bgc
      onToggled: page.set(sw.key, !checked)
    }
  }

  // the Kronos plugin is still on: it draws the clock, these settings wait
  Rectangle {
    visible: page.mod && page.mod.kronosOn
    width: parent.width
    height: kronosRow.implicitHeight + Style.space(20)
    radius: SH.HubStyle.radiusSmall
    color: SH.HubStyle.tint(page.accent, 0.14)
    Row {
      id: kronosRow
      x: Style.space(12); anchors.verticalCenter: parent.verticalCenter
      width: parent.width - Style.space(24)
      spacing: Style.space(10)
      Text {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - switchBtn.width - parent.spacing
        wrapMode: Text.Wrap
        text: page.ru ? "Сейчас часы рисует плагин Kronos. Выключите его, чтобы перейти на встроенные часы с этими настройками."
                      : "The Kronos plugin draws the clock now. Turn it off to switch to the built-in clock with these settings."
        color: page.fg
        font.family: page.ff; font.pixelSize: Style.font.caption
      }
      SH.HubChip {
        id: switchBtn
        anchors.verticalCenter: parent.verticalCenter
        label: page.ru ? "Перейти" : "Switch"
        on: true
        fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
        onClicked: page.mod.notch.setPluginEnabled("mash2rafi.kronos", false)
      }
    }
  }

  SH.HubRow {
    title: page.ru ? "Показывать на рабочем столе" : "Show on the desktop"; fg: page.fg; fontFamily: page.ff
    SH.HubSwitch {
      checked: page.cfg.clockEnabled !== false
      fg: page.fg; accent: page.accent; ink: page.bgc
      onToggled: page.set("clockEnabled", !checked)
    }
  }
  SH.HubRow {
    title: page.ru ? "Стиль часов" : "Clock style"; fg: page.fg; fontFamily: page.ff
    SH.HubSelect {
      width: Style.space(176); showLabel: false
      options: [{ value: "kronos", label: page.ru ? "Kronos (кольца)" : "Kronos (rings)" }, { value: "type", label: page.ru ? "Крупный шрифт" : "Typographic" },
                { value: "flip", label: page.ru ? "Перекидные" : "Flip" }, { value: "day", label: page.ru ? "Кольцо дня" : "Day ring" }]
      value: page.mod ? String(page.mod.opt("style", "kronos")) : "kronos"
      foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
      onChanged: function(v) { page.mod.persist({ style: v }) }
    }
  }
  SH.HubRow {
    title: page.ru ? "Вид колец" : "Ring layout"; fg: page.fg; fontFamily: page.ff
    SH.HubSelect {
      width: Style.space(176); showLabel: false
      options: [{ value: "orbit", label: page.ru ? "Кольца" : "Orbit" }, { value: "digital", label: page.ru ? "Цифровые" : "Digital" }]
      value: String(page.cfg.centerLayout || "orbit")
      foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
      onChanged: function(v) { page.set("centerLayout", v) }
    }
  }
  SH.HubRow {
    title: page.ru ? "Цвет колец" : "Ring colours"; fg: page.fg; fontFamily: page.ff
    SH.HubSelect {
      width: Style.space(176); showLabel: false
      options: [{ value: "theme", label: page.ru ? "Как тема" : "Theme" }, { value: "accent", label: page.ru ? "Акцент" : "Accent" },
                { value: "contrast", label: page.ru ? "Контраст" : "Contrast" }, { value: "mono", label: page.ru ? "Один цвет" : "Mono" }]
      value: String(page.cfg.accentMode || "theme")
      foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
      onChanged: function(v) { page.set("accentMode", v) }
    }
  }
  SH.HubRow {
    title: page.ru ? "Цифры" : "Digits"; fg: page.fg; fontFamily: page.ff
    SH.HubSelect {
      width: Style.space(176); showLabel: false
      options: [{ value: "default", label: page.ru ? "Как в теме" : "Theme font" }, { value: "gothic", label: page.ru ? "Готические (как у цитат)" : "Blackletter (like quotes)" },
                { value: "serif", label: page.ru ? "С засечками" : "Serif" }]
      value: page.mod ? String(page.mod.opt("digits", "default")) : "default"
      foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
      onChanged: function(v) { page.mod.persist({ digits: v }) }
    }
  }
  SH.HubRow {
    title: page.ru ? "Размер" : "Size"; fg: page.fg; fontFamily: page.ff
    SH.HubSlider {
      width: Style.space(176)
      minimum: 0.5; maximum: 2.5; step: 0.05
      value: Number(page.cfg.scale || 1)
      fillColor: page.accent; fontFamily: page.ff
      onReleased: function(v) { page.set("scale", Math.round(v * 100) / 100) }
    }
  }
  // Kronos's finer knobs (its rings and digits)
  component Knob: SH.HubRow {
    id: kn
    property string key: ""
    property real from: 0
    property real to: 1
    property real step: 0.05
    property real fallback: 1
    property var fmt: function(v) { return Math.round(v * 100) + "%" }
    visible: page.mod && String(page.mod.opt("style", "kronos")) === "kronos"
    fg: page.fg; fontFamily: page.ff
    SH.HubSlider {
      width: Style.space(176)
      minimum: kn.from; maximum: kn.to; step: kn.step
      value: page.cfg[kn.key] !== undefined ? Number(page.cfg[kn.key]) : kn.fallback
      format: kn.fmt
      fillColor: page.accent; fontFamily: page.ff
      onReleased: function(v) { page.set(kn.key, Math.round(v * 100) / 100) }
    }
  }
  Knob { key: "hourScale"; title: page.ru ? "Размер цифр часов" : "Hour digits"; from: 0.5; to: 2.5; fallback: 0.75 }
  Knob { key: "minuteCapsuleScale"; title: page.ru ? "Капсула минут" : "Minute capsule"; from: 0.5; to: 2.5; fallback: 1 }
  Knob { key: "ringDiameter"; title: page.ru ? "Диаметр колец" : "Ring size"; from: 0.25; to: 0.55; step: 0.01; fallback: 0.4 }
  Knob { key: "ringGap"; title: page.ru ? "Расстояние между кольцами" : "Ring gap"; from: 24; to: 100; step: 1; fallback: 48; fmt: function(v) { return Math.round(v) + " px" } }
  Knob { key: "ringArcDegrees"; title: page.ru ? "Длина дуги колец" : "Ring arc"; from: 60; to: 360; step: 10; fallback: 120; fmt: function(v) { return Math.round(v) + "°" } }
  Knob { key: "ringTransparency"; title: page.ru ? "Непрозрачность колец" : "Ring opacity"; from: 0; to: 1; fallback: 1 }
  // move the hour (and the date) inside the clock's block
  Knob { key: "hourOffsetX"; title: page.ru ? "Час: влево — вправо" : "Hour: left — right"; from: -300; to: 300; step: 2; fallback: 0; fmt: function(v) { return Math.round(v) + " px" } }
  Knob { key: "hourOffsetY"; title: page.ru ? "Час: вверх — вниз" : "Hour: up — down"; from: -300; to: 300; step: 2; fallback: 0; fmt: function(v) { return Math.round(v) + " px" } }
  Knob { key: "dateOffsetX"; title: page.ru ? "Дата: влево — вправо" : "Date: left — right"; from: -300; to: 300; step: 2; fallback: 0; fmt: function(v) { return Math.round(v) + " px" } }
  Knob { key: "dateOffsetY"; title: page.ru ? "Дата: вверх — вниз" : "Date: up — down"; from: -300; to: 300; step: 2; fallback: 0; fmt: function(v) { return Math.round(v) + " px" } }
  Sw { key: "showRingLabels"; title: page.ru ? "Подписи на кольцах" : "Ring labels"; visible: page.mod && String(page.mod.opt("style", "kronos")) === "kronos" }
  Sw { key: "showSecondCapsule"; title: page.ru ? "Капсула секунд" : "Seconds capsule"; visible: page.mod && String(page.mod.opt("style", "kronos")) === "kronos" }
  Sw { key: "use24h"; title: page.ru ? "24-часовой формат" : "24-hour clock" }
  Sw { key: "showSeconds"; title: page.ru ? "Кольцо секунд" : "Seconds ring" }
  Sw { key: "showDate"; title: page.ru ? "Дата" : "Date" }
}
