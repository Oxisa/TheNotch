import QtQuick
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// The clock's card in Settings → Widgets.
Column {
  id: page
  property var mod: null
  spacing: Style.space(10)

  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
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

  readonly property bool kronos: page.mod && String(page.mod.opt("style", "kronos")) === "kronos"
  component Group: SH.HubCaption { fg: page.fg; fontFamily: page.ff }

  // ------------------------------------------------------------ the clock
  Group { text: page.ru ? "Часы" : "Clock"; icon: "\u{f0150}" }
  SH.HubRow {
    title: page.ru ? "Показывать на рабочем столе" : "Show on the desktop"; fg: page.fg; fontFamily: page.ff
    SH.HubSwitch {
      checked: page.cfg.clockEnabled !== false
      fg: page.fg; accent: page.accent; ink: page.bgc
      onToggled: page.set("clockEnabled", !checked)
    }
  }
  SH.HubRow {
    title: page.ru ? "Вид часов" : "Clock look"
    hint: page.ru ? "Kronos — большой час и кольца минут и секунд; остальные — простые" : "Kronos is a big hour with minute and second rings; the others are simple"
    fg: page.fg; fontFamily: page.ff
    SH.HubSelect {
      width: Style.space(150); showLabel: false
      options: [{ value: "kronos", label: page.ru ? "Kronos (кольца)" : "Kronos (rings)" }, { value: "type", label: page.ru ? "Крупный шрифт" : "Typographic" },
                { value: "flip", label: page.ru ? "Перекидные" : "Flip" }, { value: "day", label: page.ru ? "Кольцо дня" : "Day ring" }]
      value: page.mod ? String(page.mod.opt("style", "kronos")) : "kronos"
      foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
      onChanged: function(v) { page.mod.persist({ style: v }) }
    }
  }
  SH.HubRow {
    title: page.ru ? "Шрифт цифр" : "Digit font"; fg: page.fg; fontFamily: page.ff
    SH.HubSelect {
      width: Style.space(150); showLabel: false
      options: [{ value: "default", label: page.ru ? "Как у виджетов" : "Widget font" }, { value: "gothic", label: page.ru ? "Готический (как у цитат)" : "Blackletter (like quotes)" },
                { value: "serif", label: page.ru ? "С засечками" : "Serif" }]
      value: page.mod ? String(page.mod.opt("digits", "default")) : "default"
      foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
      onChanged: function(v) { page.mod.persist({ digits: v }) }
    }
  }
  SH.HubRow {
    title: page.ru ? "Размер всех часов" : "Size of the whole clock"
    hint: page.ru ? "Увеличивает часы целиком, вместе с кольцами" : "Makes the whole clock bigger, rings included"
    fg: page.fg; fontFamily: page.ff
    SH.HubSlider {
      width: Style.space(150)
      minimum: 0.5; maximum: 2.5; step: 0.05
      value: Number(page.cfg.scale || 1)
      fillColor: page.accent; fontFamily: page.ff
      onReleased: function(v) { page.set("scale", Math.round(v * 100) / 100) }
    }
  }
  Sw { key: "use24h"; title: page.ru ? "24-часовой формат" : "24-hour clock"; hint: page.ru ? "Выкл — 1–12 часов" : "Off — 1 to 12" }
  Sw { key: "showDate"; title: page.ru ? "Дата и день недели" : "Date and weekday"; hint: page.ru ? "Под большим часом (у Kronos) или под временем" : "Under the big hour (Kronos) or under the time" }

  // Kronos's finer knobs
  component Knob: SH.HubRow {
    id: kn
    property string key: ""
    property real from: 0
    property real to: 1
    property real step: 0.05
    property real fallback: 1
    property var fmt: function(v) { return Math.round(v * 100) + "%" }
    visible: page.kronos
    fg: page.fg; fontFamily: page.ff
    SH.HubSlider {
      width: Style.space(150)
      minimum: kn.from; maximum: kn.to; step: kn.step
      value: page.cfg[kn.key] !== undefined ? Number(page.cfg[kn.key]) : kn.fallback
      format: kn.fmt
      fillColor: page.accent; fontFamily: page.ff
      onReleased: function(v) { page.set(kn.key, Math.round(v * 100) / 100) }
    }
  }
  readonly property var px: function(v) { return (v > 0 ? "+" : "") + Math.round(v) + " px" }

  // ------------------------------------------------- Kronos: the big hour
  Group { visible: page.kronos; text: page.ru ? "Большой час (Kronos)" : "The big hour (Kronos)"; icon: "\u{f0284}" }
  Knob { key: "hourScale"; title: page.ru ? "Размер большого часа" : "Big hour size"; hint: page.ru ? "Только цифра часа, кольца не меняются" : "Only the hour digits; the rings stay"; from: 0.5; to: 2.5; fallback: 0.75 }
  Knob { key: "hourOffsetX"; title: page.ru ? "Час — сдвиг влево / вправо" : "Hour — move left / right"; from: -300; to: 300; step: 2; fallback: 0; fmt: page.px }
  Knob { key: "hourOffsetY"; title: page.ru ? "Час — сдвиг вверх / вниз" : "Hour — move up / down"; from: -300; to: 300; step: 2; fallback: 0; fmt: page.px }
  Knob { key: "dateOffsetX"; title: page.ru ? "Дата — сдвиг влево / вправо" : "Date — move left / right"; from: -300; to: 300; step: 2; fallback: 0; fmt: page.px }
  Knob { key: "dateOffsetY"; title: page.ru ? "Дата — сдвиг вверх / вниз" : "Date — move up / down"; from: -300; to: 300; step: 2; fallback: 0; fmt: page.px }

  // --------------------------------------- Kronos: minute and second rings
  Group { visible: page.kronos; text: page.ru ? "Кольца минут и секунд (Kronos)" : "Minute and second rings (Kronos)"; icon: "\u{f0e09}" }
  SH.HubRow {
    visible: page.kronos
    title: page.ru ? "Как показывать минуты и секунды" : "How minutes and seconds show"; fg: page.fg; fontFamily: page.ff
    SH.HubSelect {
      width: Style.space(150); showLabel: false
      options: [{ value: "orbit", label: page.ru ? "На кольцах" : "On rings" }, { value: "digital", label: page.ru ? "Цифрами" : "As digits" }]
      value: String(page.cfg.centerLayout || "orbit")
      foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
      onChanged: function(v) { page.set("centerLayout", v) }
    }
  }
  SH.HubRow {
    visible: page.kronos
    title: page.ru ? "Цвет колец" : "Ring colour"; fg: page.fg; fontFamily: page.ff
    SH.HubSelect {
      width: Style.space(150); showLabel: false
      options: [{ value: "theme", label: page.ru ? "Как тема" : "Theme" }, { value: "accent", label: page.ru ? "Акцент" : "Accent" },
                { value: "contrast", label: page.ru ? "Контраст" : "Contrast" }, { value: "mono", label: page.ru ? "Один цвет" : "Mono" }]
      value: String(page.cfg.accentMode || "theme")
      foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
      onChanged: function(v) { page.set("accentMode", v) }
    }
  }
  Knob { key: "ringDiameter"; title: page.ru ? "Размер колец" : "Ring size"; from: 0.25; to: 0.55; step: 0.01; fallback: 0.4 }
  Knob { key: "ringGap"; title: page.ru ? "Расстояние между кольцами" : "Gap between the rings"; hint: page.ru ? "Между кольцом минут и кольцом секунд" : "Between the minute ring and the second ring"; from: 24; to: 100; step: 1; fallback: 48; fmt: function(v) { return Math.round(v) + " px" } }
  Knob { key: "ringArcDegrees"; title: page.ru ? "Какую часть круга занимают" : "How much of a circle"; hint: page.ru ? "360° — полный круг" : "360° is a full circle"; from: 60; to: 360; step: 10; fallback: 120; fmt: function(v) { return Math.round(v) + "°" } }
  Knob { key: "ringTransparency"; title: page.ru ? "Видимость колец" : "Ring visibility"; hint: page.ru ? "0% — колец не видно, остаются метки" : "0% hides the rings, the markers stay"; from: 0; to: 1; fallback: 1 }
  Knob { key: "minuteCapsuleScale"; title: page.ru ? "Размер метки минут" : "Minute marker size"; hint: page.ru ? "Кружок с минутами, что едет по кольцу" : "The minutes' bubble that travels the ring"; from: 0.5; to: 2.5; fallback: 1 }
  Sw { visible: page.kronos; key: "showRingLabels"; title: page.ru ? "Числа вдоль колец" : "Numbers along the rings" }
  Sw { visible: page.kronos; key: "showSeconds"; title: page.ru ? "Кольцо секунд" : "Second ring" }
  Sw { visible: page.kronos; key: "showSecondCapsule"; title: page.ru ? "Метка секунд" : "Second marker"; hint: page.ru ? "Маленький кружок с секундами на кольце" : "The small seconds' bubble on the ring" }
}
