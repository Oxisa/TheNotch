import QtQuick
import qs.Commons
import "../../../osia.soundhub" as SH

// Weather's card in Settings → Widgets: show, look, background.
Column {
  id: page
  property var mod: null
  spacing: Style.space(10)
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Style.font.family
  function t(a, b) { return mod ? mod.t(a, b) : b }

  SH.HubRow {
    title: page.t("Показывать на рабочем столе", "Show on the desktop")
    hint: page.mod && !page.mod.place ? page.t("Сначала выберите город в настройках «Погоды»", "Pick a city in Weather's settings first") : ""
    fg: page.fg; fontFamily: page.ff
    SH.HubSwitch {
      checked: page.mod ? page.mod.deskEnabled : false
      fg: page.fg; accent: page.accent; ink: page.bgc
      onToggled: page.mod.setDeskEnabled(!checked)
    }
  }
  SH.HubRow {
    title: page.t("Вид", "Look"); fg: page.fg; fontFamily: page.ff
    SH.HubSelect {
      width: Style.space(176); showLabel: false
      options: [{ value: "capsule", label: page.t("Капсула", "Capsule") }, { value: "card", label: page.t("Карточка", "Card") },
                { value: "line", label: page.t("Строка", "Line") },
                { value: "full", label: page.t("Полный с прогнозом", "Full with forecast") }, { value: "round", label: page.t("Круглый", "Round") },
                { value: "tile", label: page.t("Плитка", "Tile") }]
      value: page.mod ? page.mod.look : "capsule"
      foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
      onChanged: function(v) { page.mod.persist({ look: v }) }
    }
  }
  SH.HubRow {
    title: page.t("Фон", "Background"); fg: page.fg; fontFamily: page.ff
    SH.HubSlider {
      width: Style.space(176)
      minimum: 0.2; maximum: 1; step: 0.05
      value: page.mod ? Number(page.mod.opt("opacity", 0.85)) : 0.85
      fillColor: page.accent; fontFamily: page.ff
      onReleased: function(v) { page.mod.persist({ opacity: Math.round(v * 100) / 100 }) }
    }
  }
}
