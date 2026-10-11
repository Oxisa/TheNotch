import QtQuick
import Quickshell
import qs.Commons
import "../../../osia.soundhub" as SH

Column {
  id: page
  property var notch: null
  // which part to show: "notch" (where and how it looks), "system" (language)
  // or "events" (which events pop out of the notch)
  property string part: "notch"
  spacing: SH.HubStyle.gap

  readonly property color fg: notch ? notch.fg : "white"
  readonly property color accent: notch ? notch.accent : "white"
  readonly property color bgc: Color.background
  readonly property string ff: notch ? notch.ff : ""
  function t(k) { return notch ? notch.t(k) : k }

  component Card: SH.HubCard {
    default property alias rows: body.data
    width: page.width
    height: body.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    Column {
      id: body
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      spacing: Style.space(10)
    }
  }

  Card {
    visible: page.part === "notch"
    SH.HubRow {
      title: page.t("monitor"); fg: page.fg; fontFamily: page.ff
      SH.HubSelect {
        width: Style.space(176); showLabel: false
        options: Quickshell.screens.map(function(sc) { return { value: sc.name, label: sc.name + (sc.model ? " · " + sc.model : "") } })
        value: page.notch ? page.notch.notchScreen : ""
        foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
        onChanged: function(v) { page.notch.persist({ screen: v }) }
      }
    }
    SH.HubRow {
      title: page.t("edge"); fg: page.fg; fontFamily: page.ff
      Row {
        spacing: Style.space(4)
        Repeater {
          model: ["top", "right", "bottom", "left"]
          delegate: SH.HubChip {
            required property string modelData
            iconOnly: true
            icon: modelData === "top" ? "󰁝" : modelData === "bottom" ? "󰁅" : modelData === "left" ? "󰁍" : "󰁔"
            label: page.t("edge." + modelData)
            on: page.notch && page.notch.edge === modelData
            fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
            onClicked: page.notch.persist({ edge: modelData })
          }
        }
      }
    }
    SH.HubRow {
      title: page.t("hideBar"); hint: page.t("hideBarHint"); fg: page.fg; fontFamily: page.ff
      SH.HubSwitch {
        checked: page.notch && page.notch.hideBar
        fg: page.fg; accent: page.accent; ink: page.bgc
        onToggled: page.notch.persist({ hideBar: !checked })
      }
    }
  }

  Card {
    visible: page.part !== "events"
    SH.HubRow {
      visible: page.part === "notch"
      title: page.t("look"); fg: page.fg; fontFamily: page.ff
      SH.HubSelect {
        width: Style.space(160); showLabel: false
        options: [{ value: "theme", label: page.t("look.theme") }, { value: "black", label: page.t("look.black") }]
        value: page.notch ? String(page.notch.opt("look", "theme")) : "theme"
        foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
        onChanged: function(v) { page.notch.persist({ look: v }) }
      }
    }
    SH.HubRow {
      visible: page.part === "system"
      title: page.t("language"); fg: page.fg; fontFamily: page.ff
      SH.HubSelect {
        width: Style.space(160); showLabel: false
        options: [{ value: "ru", label: "Русский" }, { value: "en", label: "English" }]
        value: page.notch ? page.notch.lang : "ru"
        foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
        onChanged: function(v) { page.notch.persist({ lang: v }) }
      }
    }
  }

  Card {
    visible: page.part === "events"
    SH.HubRow {
      title: page.t("eventsVolume"); fg: page.fg; fontFamily: page.ff
      SH.HubSwitch {
        checked: page.notch && page.notch.opt("eventVolume", true) === true
        fg: page.fg; accent: page.accent; ink: page.bgc
        onToggled: page.notch.persist({ eventVolume: !checked })
      }
    }
    SH.HubRow {
      title: page.t("eventsTrack"); fg: page.fg; fontFamily: page.ff
      SH.HubSwitch {
        checked: page.notch && page.notch.opt("eventTrack", true) === true
        fg: page.fg; accent: page.accent; ink: page.bgc
        onToggled: page.notch.persist({ eventTrack: !checked })
      }
    }
  }
}
