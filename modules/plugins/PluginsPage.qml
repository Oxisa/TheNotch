import QtQuick
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// Every Omarchy shell plugin with an on/off switch (omarchy plugin
// enable|disable), third-party first. TheNotch itself isn't listed.
Column {
  id: page
  property var notch: null
  spacing: SH.HubStyle.gap

  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  readonly property bool ru: notch && notch.lang === "ru"
  property string filter: ""

  readonly property var all: (notch ? notch.omarchyPlugins : []).filter(function(p) {
    if (p.id === "osia.thenotch") return false
    var f = page.filter.toLowerCase()
    return !f || String(p.name).toLowerCase().indexOf(f) >= 0 || String(p.id).toLowerCase().indexOf(f) >= 0
  })
  readonly property var groups: [
    { title: ru ? "Сторонние" : "Community", items: all.filter(function(p) { return !p.firstParty }) },
    { title: ru ? "Встроенные" : "Built-in", items: all.filter(function(p) { return p.firstParty }) }
  ]

  Component.onCompleted: if (notch) notch.refreshPlugins()

  Row {
    width: parent.width
    spacing: Style.space(8)
    SH.HubField {
      id: search
      width: parent.width - refresh.width - parent.spacing
      icon: "󰍉"
      placeholderText: page.ru ? "Найти плагин…" : "Find a plugin…"
      fg: page.fg; accent: page.accent; fontFamily: page.ff
      onTextEdited: page.filter = text
    }
    SH.HubChip {
      id: refresh
      iconOnly: true
      icon: "󰑓"
      label: page.ru ? "Обновить" : "Refresh"
      fg: page.fg; accent: page.accent; fontFamily: page.ff
      onClicked: page.notch.refreshPlugins()
    }
  }

  Repeater {
    model: page.groups
    delegate: Column {
      id: grp
      required property var modelData
      visible: modelData.items.length > 0
      width: page.width
      spacing: Style.space(6)
      SH.HubCaption { text: grp.modelData.title + "  ·  " + grp.modelData.items.length; fg: page.fg; fontFamily: page.ff }
      SH.HubCard {
        width: parent.width
        height: list.implicitHeight + SH.HubStyle.pad * 2
        fg: page.fg; accent: page.accent
        Column {
          id: list
          x: SH.HubStyle.pad; y: SH.HubStyle.pad
          width: parent.width - SH.HubStyle.pad * 2
          spacing: Style.space(8)
          Repeater {
            model: grp.modelData.items
            delegate: SH.HubRow {
              required property var modelData
              title: modelData.name
              hint: modelData.id + "  ·  " + (modelData.kinds || []).join(", ")
              fg: page.fg; fontFamily: page.ff
              SH.HubSwitch {
                checked: modelData.enabled === true
                enabled: modelData.canDisable !== false && !page.notch.pluginsBusy
                opacity: enabled ? 1 : 0.4
                fg: page.fg; accent: page.accent; ink: page.bgc
                onToggled: page.notch.setPluginEnabled(modelData.id, !checked)
              }
            }
          }
        }
      }
    }
  }
}
