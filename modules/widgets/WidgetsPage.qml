import QtQuick
import qs.Commons
import "../../../osia.soundhub" as SH

Column {
  id: page
  property var notch: null
  spacing: SH.HubStyle.gap

  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Style.font.family
  readonly property bool ru: notch && notch.lang === "ru"

  Repeater {
    model: page.notch ? page.notch.widgetModules : []
    delegate: Column {
      id: w
      required property var modelData
      readonly property bool on: modelData.active
      width: page.width
      spacing: Style.space(6)

      SH.HubCaption {
        text: w.modelData.widgetTitle
        icon: w.modelData.widgetIcon
        fg: page.fg; fontFamily: page.ff
        Text {
          text: "\u{f0431}  " + w.modelData.title
          color: Qt.darker(page.fg, 1.8)
          font.family: page.ff; font.pixelSize: Style.font.caption - 1
        }
      }

      // the module is on: the widget's own settings
      SH.HubCard {
        visible: w.on
        width: parent.width
        height: body.item ? body.item.implicitHeight + SH.HubStyle.pad * 2 : 0
        fg: page.fg; accent: page.accent
        Loader {
          id: body
          x: SH.HubStyle.pad; y: SH.HubStyle.pad
          width: parent.width - SH.HubStyle.pad * 2
          active: w.on
          sourceComponent: w.modelData.widgetPage
        }
      }

      // the module is off: grey, and a way to switch it on
      SH.HubCard {
        visible: !w.on
        width: parent.width
        height: offRow.implicitHeight + SH.HubStyle.pad * 2
        fg: page.fg; accent: page.accent
        opacity: 0.75
        Row {
          id: offRow
          x: SH.HubStyle.pad; y: SH.HubStyle.pad
          width: parent.width - SH.HubStyle.pad * 2
          spacing: Style.space(12)
          Text {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - enableBtn.width - parent.spacing
            wrapMode: Text.Wrap
            text: (page.ru ? "Модуль «" + w.modelData.title + "» выключен — виджет недоступен."
                           : "The " + w.modelData.title + " module is off, so this widget is unavailable.")
            color: Qt.darker(page.fg, 1.5)
            font.family: page.ff; font.pixelSize: Style.font.caption
          }
          SH.HubChip {
            id: enableBtn
            anchors.verticalCenter: parent.verticalCenter
            icon: "\u{f0425}"
            label: page.ru ? "Включить модуль" : "Turn the module on"
            on: true
            fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
            onClicked: page.notch.setModuleEnabled(w.modelData.moduleId, true)
          }
        }
      }
    }
  }
}
