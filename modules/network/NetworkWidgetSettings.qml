import QtQuick
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// Network's widgets in Settings → Widgets and in the layout editor's panel.
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
    title: page.t("Сеть на рабочем столе", "Network on the desktop"); hint: page.t("Подключение, скорость, задержка", "Connection, speed, latency")
    fg: page.fg; fontFamily: page.ff
    SH.HubSwitch { checked: page.mod ? page.mod.deskEnabled : false; fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.mod.setDeskEnabled(!checked) }
  }
  SH.HubRow {
    title: page.t("Вид", "Look"); hint: page.t("Карточка с графиком или кольцо сигнала", "A card with a graph or a signal ring")
    fg: page.fg; fontFamily: page.ff
    Row {
      spacing: Style.space(4)
      Repeater {
        model: [{ v: "card", l: page.t("Карточка", "Card") }, { v: "ring", l: page.t("Кольцо", "Ring") }]
        delegate: SH.HubChip {
          required property var modelData
          label: modelData.l; on: page.mod && page.mod.deskLook === modelData.v; subtle: true
          fg: page.fg; accent: page.accent; fontFamily: page.ff
          onClicked: page.mod.persist({ look: modelData.v })
        }
      }
    }
  }
}
