import QtQuick
import qs.Commons
import "../../../osia.soundhub" as SH

// Network's widgets in Settings → Widgets and in the layout editor's panel.
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
    title: page.t("Карточка сети", "Network card"); hint: page.t("Подключение, скорость с графиком, задержка, туннель", "Connection, speed with a graph, latency, tunnel")
    fg: page.fg; fontFamily: page.ff
    SH.HubSwitch { checked: page.mod ? page.mod.deskEnabled : false; fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.mod.setDeskEnabled(!checked) }
  }
  SH.HubRow {
    title: page.t("Кольцо сигнала", "Signal ring"); hint: page.t("Минимально: сигнал Wi-Fi и скорость", "Minimal: Wi-Fi signal and speed")
    fg: page.fg; fontFamily: page.ff
    SH.HubSwitch { checked: page.mod ? page.mod.opt("ringWidget", false) === true : false; fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.mod.persist({ ringWidget: !checked }) }
  }
}
