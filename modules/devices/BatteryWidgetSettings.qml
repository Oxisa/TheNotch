import QtQuick
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// The Batteries widget's card (Settings → Widgets and the editor's panel).
Column {
  id: page
  property var mod: null
  spacing: Style.space(10)
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }
  SH.HubRow {
    title: page.t("Показывать на рабочем столе", "Show on the desktop")
    hint: page.t("Наушники, мыши, клавиатуры, геймпады — у кого есть заряд", "Headphones, mice, keyboards, gamepads — whatever reports a charge")
    fg: page.fg; fontFamily: page.ff
    SH.HubSwitch { checked: page.mod ? page.mod.deskEnabled : false; fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.mod.setDeskEnabled(!checked) }
  }
  SH.HubRow {
    title: page.t("Вид", "Look"); fg: page.fg; fontFamily: page.ff
    SH.HubSelect {
      width: Style.space(176); showLabel: false
      options: [{ value: "rings", label: page.t("Кольца (как на Mac)", "Rings (like a Mac)") }, { value: "list", label: page.t("Список", "List") }]
      value: page.mod ? String(page.mod.opt("look", "rings")) : "rings"
      foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
      onChanged: function(v) { page.mod.persist({ look: v }) }
    }
  }
  SH.HubRow {
    title: page.t("Названия", "Names"); fg: page.fg; fontFamily: page.ff
    SH.HubSwitch { checked: page.mod ? page.mod.opt("names", true) !== false : true; fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.mod.persist({ names: !checked }) }
  }
}
