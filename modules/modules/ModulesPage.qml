import QtQuick
import qs.Commons
import "../../../osia.soundhub" as SH

// One card per module: icon, name, what it does, on/off.
Column {
  id: page
  property var notch: null
  spacing: SH.HubStyle.gap

  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Style.font.family

  Text {
    width: parent.width
    wrapMode: Text.Wrap
    leftPadding: Style.space(4)
    text: page.notch && page.notch.lang === "ru"
          ? "Выключенный модуль пропадает из чёлки: без иконки, событий и виджета."
          : "A switched-off module leaves the notch: no icon, no events, no widget."
    color: Qt.darker(page.fg, 1.6)
    font.family: page.ff; font.pixelSize: Style.font.caption
  }

  Repeater {
    model: page.notch ? page.notch.toggleModules : []
    delegate: SH.HubCard {
      id: card
      required property var modelData
      width: page.width
      height: row.implicitHeight + SH.HubStyle.pad * 2
      fg: page.fg; accent: page.accent
      selected: modelData.active
      Row {
        id: row
        x: SH.HubStyle.pad; y: SH.HubStyle.pad
        width: parent.width - SH.HubStyle.pad * 2
        spacing: Style.space(14)
        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(38); height: width; radius: width / 2
          color: card.modelData.active ? page.accent : SH.HubStyle.tint(page.fg, 0.08)
          Text {
            anchors.centerIn: parent
            text: card.modelData.icon
            color: card.modelData.active ? page.bgc : page.fg
            font.family: page.ff; font.pixelSize: Style.space(18)
          }
        }
        SH.HubRow {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - Style.space(38) - parent.spacing
          title: card.modelData.title
          hint: card.modelData.description
          fg: page.fg; fontFamily: page.ff
          SH.HubSwitch {
            checked: card.modelData.active
            fg: page.fg; accent: page.accent; ink: page.bgc
            onToggled: page.notch.setModuleEnabled(card.modelData.moduleId, !checked)
          }
        }
      }
    }
  }
}
