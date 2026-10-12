import QtQuick
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// Weather's section in the settings window: the city (search) and whether
// the temperature shows in the collapsed notch.
Column {
  id: page
  property var mod: null
  spacing: SH.HubStyle.gap
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }

  SH.HubCard {
    width: parent.width
    height: col.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    Column {
      id: col
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      spacing: Style.space(10)
      SH.HubRow {
        title: page.t("Город", "City")
        hint: page.mod && page.mod.place ? page.mod.place.name + (page.mod.place.region ? ", " + page.mod.place.region : "") + (page.mod.place.country ? ", " + page.mod.place.country : "")
                                         : page.t("Не выбран", "Not set")
        fg: page.fg; fontFamily: page.ff
      }
      Row {
        width: parent.width
        spacing: Style.space(6)
        SH.HubField {
          id: q
          width: parent.width - go.width - parent.spacing
          icon: "󰍉"
          placeholderText: page.t("Найти город…", "Find a city…")
          fg: page.fg; accent: page.accent; fontFamily: page.ff
          onAccepted: page.mod.search(text)
        }
        SH.HubChip {
          id: go
          iconOnly: true
          icon: page.mod && page.mod.searching ? "\u{f051f}" : "󰍉"
          label: page.t("Найти", "Search")
          on: true
          fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
          onClicked: page.mod.search(q.text)
        }
      }
      Repeater {
        model: page.mod ? page.mod.found : []
        delegate: Rectangle {
          required property var modelData
          width: col.width
          height: Style.space(34)
          radius: SH.HubStyle.radiusSmall
          color: SH.HubStyle.tint(page.fg, pick.containsMouse ? 0.10 : 0.05)
          Text {
            anchors.verticalCenter: parent.verticalCenter
            x: Style.space(12)
            width: parent.width - Style.space(24)
            elide: Text.ElideRight
            text: modelData.name + (modelData.region ? ", " + modelData.region : "") + (modelData.country ? ", " + modelData.country : "")
            color: page.fg
            font.family: page.ff; font.pixelSize: Style.font.caption + 1
          }
          MouseArea { id: pick; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { page.mod.choose(modelData); q.text = "" } }
        }
      }
      SH.HubRow {
        title: page.t("Температура в чёлке", "Temperature in the notch")
        hint: page.t("Рядом с часами в свёрнутой чёлке", "Next to the clock in the collapsed notch")
        fg: page.fg; fontFamily: page.ff
        SH.HubSwitch {
          checked: page.mod ? page.mod.inNotch : true
          fg: page.fg; accent: page.accent; ink: page.bgc
          onToggled: page.mod.persist({ inNotch: !checked })
        }
      }
    }
  }
}
