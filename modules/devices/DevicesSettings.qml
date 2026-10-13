import QtQuick
import Quickshell
import qs.Commons
import "../.."
import "../../vendor/soundhub" as SH
import "../../fonts"

// Settings → Bluetooth & devices.
// Everything on one page: Bluetooth on/off, your devices (connect, battery), nearby devices to pair, batteries, printers, cameras; also MAC addresses, trust, the adapter's name, print jobs, CUPS.
Column {
  id: page
  property var mod: null
  readonly property bool full: true            // everything shown: the extra bits were too few for an Advanced mode
  spacing: SH.HubStyle.gap
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }
  readonly property var st: mod ? mod.st : ({})
  readonly property var mine: (st.devices || []).filter(function(d) { return d.paired })
  readonly property var nearby: (st.devices || []).filter(function(d) { return !d.paired })
  SettingsTabs {
    id: tabs
    // printers only once there is one (or you're adding one); batteries are
    // the Batteries widget and cameras the Camera section
    tabs: [{ id: "bt", label: "Bluetooth", icon: "\u{f00af}" }]
          .concat(page.hasPrinters || page.addingPrinter ? [{ id: "print", label: page.t("Принтеры", "Printers"), icon: "\u{f042a}" }] : [])
  }
  readonly property string tab: tabs.current
  readonly property bool hasPrinters: !!(st.printers && st.printers.list && st.printers.list.length)
  property bool addingPrinter: false


  component Card: SH.HubCard {
    width: page.width
    height: inner.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    default property alias content: inner.data
    Column {
      id: inner
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      spacing: Style.space(10)
    }
  }
  // one device row: glyph, name, state and battery, actions
  component DeviceRow: Rectangle {
    id: row
    property var d: null
    property bool pairing: false
    width: parent ? parent.width : 0
    height: Style.space(54)
    radius: SH.HubStyle.radiusSmall + Style.space(2)
    color: d && d.connected ? SH.HubStyle.tint(page.accent, 0.14) : SH.HubStyle.tint(page.fg, rm.containsMouse ? 0.08 : 0.04)
    readonly property bool working: page.mod && page.mod.busy.indexOf(d ? d.mac : "~") >= 0
    Rectangle {
      id: ic
      x: Style.space(10); anchors.verticalCenter: parent.verticalCenter
      width: Style.space(36); height: width; radius: width / 2
      color: SH.HubStyle.tint(row.d && row.d.connected ? page.accent : page.fg, 0.16)
      Text { anchors.centerIn: parent; text: page.mod ? page.mod.glyph(row.d ? row.d.kind : "") : ""; color: row.d && row.d.connected ? page.accent : page.fg; font.family: page.ff; font.pixelSize: Style.space(18) }
    }
    Column {
      anchors.left: ic.right; anchors.leftMargin: Style.space(12)
      anchors.right: acts.left; anchors.rightMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
      Text { width: parent.width; elide: Text.ElideRight; text: row.d ? row.d.name : ""; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.body; font.bold: !!(row.d && row.d.connected) }
      Text {
        width: parent.width; elide: Text.ElideRight
        text: !row.d ? "" : row.working ? page.t("подождите…", "working…")
              : (row.d.connected ? page.t("подключено", "connected") : row.d.paired ? page.t("не подключено", "not connected") : page.t("рядом", "nearby"))
                + (row.d.battery !== null ? "  ·  \u{f0079} " + row.d.battery + "%" : "")
                + (page.full ? "  ·  " + row.d.mac : "")
        color: row.d && row.d.connected ? page.accent : Qt.darker(page.fg, 1.5)
        font.family: page.ff; font.pixelSize: Style.font.caption - 1
      }
    }
    MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
    Row {
      id: acts
      anchors.right: parent.right; anchors.rightMargin: Style.space(10)
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(4)
      SH.HubChip {
        visible: !!row.d
        label: !row.d ? "" : !row.d.paired ? page.t("Подключить", "Pair") : row.d.connected ? page.t("Отключить", "Disconnect") : page.t("Подключить", "Connect")
        on: !!(row.d && !row.d.connected)
        h: Style.space(28)
        fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
        onClicked: page.mod.bt(!row.d.paired ? "pair" : row.d.connected ? "disconnect" : "connect", row.d.mac)
      }
      SH.HubChip {
        visible: !!(row.d && row.d.paired)
        iconOnly: true; icon: "\u{f01b4}"
        label: page.t("Забыть устройство", "Forget the device")
        h: Style.space(28)
        fg: page.fg; accent: page.accent; fontFamily: page.ff
        property int confirm: 0
        onClicked: { if (++confirm >= 2) { page.mod.bt("remove", row.d.mac); confirm = 0 } else forgetReset.restart() }
        Timer { id: forgetReset; interval: 3000; onTriggered: parent.confirm = 0 }
      }
    }
  }

  // ------------------------------------------------------- Bluetooth
  Card {
    visible: page.tab === "bt"
    SH.HubRow {
      title: "Bluetooth"
      hint: !page.st.bt || !page.st.bt.present ? page.t("Адаптер не найден", "No adapter found")
            : page.st.bt.powered ? page.t("Включён", "On") + (page.full && page.st.bt.name ? page.t(" · виден как «", " · visible as “") + page.st.bt.name + page.t("»", "”") : "")
            : page.t("Выключен", "Off")
      fg: page.fg; fontFamily: page.ff
      SH.HubSwitch {
        checked: !!(page.st.bt && page.st.bt.powered)
        fg: page.fg; accent: page.accent; ink: page.bgc
        onToggled: page.mod.cmd(["bt", "power", checked ? "off" : "on"])
      }
    }
    Text {
      visible: !!(page.mod && page.mod.error)
      width: parent.width; wrapMode: Text.Wrap
      text: page.mod ? page.mod.error : ""
      color: Color.urgent; font.family: page.ff; font.pixelSize: Style.font.caption
    }
    Column {
      visible: !!(page.st.bt && page.st.bt.powered)
      width: parent.width
      spacing: Style.space(6)
      Repeater { model: page.mine; delegate: DeviceRow { required property var modelData; d: modelData } }
      Item { width: 1; height: Style.space(4) }
      Item {
        width: parent.width; height: Style.space(30)
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: page.t("Рядом", "Nearby") + (page.nearby.length ? " · " + page.nearby.length : "")
          color: Qt.darker(page.fg, 1.4); font.family: page.ff; font.pixelSize: Style.font.caption; font.bold: true
        }
        SH.HubChip {
          anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
          icon: page.mod && page.mod.scanning ? "\u{f051f}" : "\u{f0349}"
          label: page.mod && page.mod.scanning ? page.t("Ищу…", "Searching…") : page.t("Найти устройства", "Find devices")
          on: !!(page.mod && page.mod.scanning)
          h: Style.space(28)
          fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
          onClicked: page.mod.scan()
        }
      }
      Repeater { model: page.nearby; delegate: DeviceRow { required property var modelData; d: modelData } }
      Text {
        visible: page.nearby.length === 0
        text: page.t("Переведите устройство в режим сопряжения и нажмите «Найти».", "Put the device in pairing mode and press Find.")
        color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption - 1
      }
    }
  }
  // no printer yet: the way in stays here (the Printers tab appears once one is added)
  Card {
    visible: page.tab === "bt" && !page.hasPrinters
    SH.HubRow {
      width: parent.width
      icon: "\u{f042a}"
      title: page.t("Принтер", "Printer"); hint: page.t("Найти принтер в сети и подключить его", "Find a printer on the network and add it")
      fg: page.fg; fontFamily: page.ff
      SH.HubChip { icon: "\u{f0415}"; label: page.t("Подключить…", "Add…"); fg: page.fg; accent: page.accent; fontFamily: page.ff
                   onClicked: { page.addingPrinter = true; tabs.current = "print"; page.mod.cmd(["printer", "discover"]) } }
    }
  }


  // -------------------------------------------------------- printers
  Card {
    visible: page.tab === "print"
    SH.HubCaption { text: page.t("Принтеры", "Printers"); icon: "\u{f042a}"; fg: page.fg; fontFamily: page.ff }
    Repeater {
      model: page.st.printers ? page.st.printers.list : []
      delegate: SH.HubRow {
        required property var modelData
        title: modelData.name + (modelData["default"] ? page.t("  · по умолчанию", "  · default") : "")
        hint: modelData.state
        fg: page.fg; fontFamily: page.ff
        Row {
          spacing: Style.space(4)
          SH.HubChip {
            visible: !modelData["default"]
            label: page.t("По умолчанию", "Make default")
            fg: page.fg; accent: page.accent; fontFamily: page.ff
            onClicked: page.mod.cmd(["printer", "default", modelData.name])
          }
          SH.HubChip {
            label: page.t("Пробная страница", "Test page")
            fg: page.fg; accent: page.accent; fontFamily: page.ff
            onClicked: page.mod.cmd(["printer", "test", modelData.name])
          }
        }
      }
    }
    // network printers: found over Avahi, added without a driver
    SH.HubRow {
      width: parent.width
      title: page.t("Найти принтеры в сети", "Find network printers")
      hint: page.mod && page.mod.busy.indexOf("discover") >= 0 ? page.t("Ищу…", "Searching…") : page.mod && page.mod.found.length ? page.t("Найдено: ", "Found: ") + page.mod.found.length : page.t("Принтеры с AirPrint / IPP Everywhere, без драйверов", "AirPrint / IPP Everywhere printers, no drivers needed")
      fg: page.fg; fontFamily: page.ff
      SH.HubChip { icon: "\u{f0349}"; label: page.t("Искать", "Search"); fg: page.fg; accent: page.accent; fontFamily: page.ff; onClicked: page.mod.cmd(["printer", "discover"]) }
    }
    Repeater {
      model: page.mod ? page.mod.found.filter(function(f) { return !(page.st.printers && page.st.printers.list.some(function(p) { return p.name === f.name.replace(/[^A-Za-z0-9_-]+/g, "_") })) }) : []
      delegate: SH.HubRow {
        required property var modelData
        width: parent.width
        icon: "\u{f042a}"
        title: modelData.name; hint: (modelData.model ? modelData.model + " · " : "") + modelData.host
        fg: page.fg; fontFamily: page.ff
        SH.HubChip { icon: "\u{f0415}"; label: page.t("Добавить", "Add"); on: true; fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff; onClicked: page.mod.cmd(["printer", "add", modelData.name, modelData.uri]) }
      }
    }
    SH.HubRow {
      title: page.st.printers && page.st.printers.list.length ? page.t("Добавить принтер", "Add a printer") : page.t("Принтеров нет", "No printers")
      hint: page.t("Сетевые принтеры в той же сети обычно находятся сами (CUPS + Avahi)", "Network printers on the same network usually show up by themselves (CUPS + Avahi)")
      fg: page.fg; fontFamily: page.ff
      SH.HubChip {
        icon: "\u{f0415}"; label: page.t("Добавить", "Add")
        fg: page.fg; accent: page.accent; fontFamily: page.ff
        onClicked: { page.mod.notch.settingsOpen = false; Quickshell.execDetached(["xdg-open", "http://localhost:631/admin"]) }
      }
    }
    Column {
      visible: page.full && page.st.printers && page.st.printers.jobs.length > 0
      width: parent.width
      spacing: Style.space(4)
      Text { text: page.t("Очередь печати", "Print queue"); color: Qt.darker(page.fg, 1.4); font.family: page.ff; font.pixelSize: Style.font.caption; font.bold: true }
      Repeater {
        model: page.st.printers ? page.st.printers.jobs : []
        delegate: SH.HubRow {
          required property var modelData
          title: modelData.id; hint: modelData.user; fg: page.fg; fontFamily: page.ff
          SH.HubChip { label: page.t("Отменить", "Cancel"); fg: page.fg; accent: page.accent; fontFamily: page.ff; onClicked: page.mod.cmd(["printer", "cancel", modelData.id]) }
        }
      }
    }
  }

}
