import QtQuick
import Quickshell
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// Settings → Bluetooth & devices → Phone: each KDE Connect device as a card —
// on the line or not, battery, and what you can do with it.
Column {
  id: page
  property var mod: null
  spacing: SH.HubStyle.gap
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }
  readonly property var st: mod ? mod.st : ({})

  SH.HubCard {
    visible: page.mod && !page.st.daemon
    width: page.width; height: off.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    SH.HubRow {
      id: off
      x: SH.HubStyle.pad; y: SH.HubStyle.pad; width: parent.width - SH.HubStyle.pad * 2
      title: page.t("Служба KDE Connect выключена", "The KDE Connect service is off"); hint: "kcd"
      fg: page.fg; fontFamily: page.ff
      SH.HubChip { icon: "\u{f040a}"; label: page.t("Включить", "Start"); on: true; fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff; onClicked: page.mod.cmd(["start"]) }
    }
  }

  Repeater {
    model: page.st.devices || []
    delegate: SH.HubCard {
      id: card
      required property var modelData
      readonly property bool on: !!modelData.connected
      readonly property var bat: modelData.battery
      width: page.width; height: cc.implicitHeight + SH.HubStyle.pad * 2
      fg: page.fg; accent: page.accent
      Column {
        id: cc
        x: SH.HubStyle.pad; y: SH.HubStyle.pad; width: parent.width - SH.HubStyle.pad * 2
        spacing: Style.space(10)
        Row {
          spacing: Style.space(12)
          Rectangle {
            width: Style.space(44); height: width; radius: Style.space(12)
            color: card.on ? page.accent : SH.HubStyle.tint(page.fg, 0.08)
            Text { anchors.centerIn: parent; text: "\u{f011c}"; color: card.on ? page.bgc : page.fg; font.family: page.ff; font.pixelSize: Style.space(22) }
          }
          Column {
            anchors.verticalCenter: parent.verticalCenter
            Text { text: card.modelData.name; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.body + 2; font.bold: true }
            Text {
              text: card.on ? page.t("На связи", "Connected") + (card.bat && card.bat.charge !== undefined ? "  ·  " + card.bat.charge + "%" + (card.bat.charging ? page.t(" · заряжается", " · charging") : "") : "")
                            : page.t("Не на связи — откройте KDE Connect на телефоне в той же сети", "Not connected — open KDE Connect on the phone, same network")
              color: card.on ? page.accent : Qt.darker(page.fg, 1.5); font.family: page.ff; font.pixelSize: Style.font.caption
            }
          }
        }
        Flow {
          width: parent.width
          spacing: Style.space(6)
          opacity: card.on ? 1 : 0.45
          enabled: card.on
          SH.HubChip { icon: "\u{f009a}"; label: page.t("Пинг", "Ping"); fg: page.fg; accent: page.accent; fontFamily: page.ff; onClicked: page.mod.cmd(["ping", card.modelData.id]) }
          SH.HubChip { icon: "\u{f0349}"; label: page.t("Найти телефон", "Find my phone"); fg: page.fg; accent: page.accent; fontFamily: page.ff; onClicked: page.mod.cmd(["findmyphone", card.modelData.id]) }
          SH.HubChip { icon: "\u{f0552}"; label: page.t("Отправить файл…", "Send a file…"); fg: page.fg; accent: page.accent; fontFamily: page.ff; onClicked: page.mod.shareFile(card.modelData.id) }
          SH.HubChip { icon: "\u{f014c}"; label: page.t("Отправить буфер", "Send the clipboard"); fg: page.fg; accent: page.accent; fontFamily: page.ff; onClicked: page.mod.cmd(["clipboard", card.modelData.id]) }
        }
        SH.HubChip {
          property bool sure: false
          icon: "\u{f0156}"; label: sure ? page.t("Точно отвязать?", "Unpair, sure?") : page.t("Отвязать", "Unpair")
          subtle: true; h: Style.space(26)
          fg: page.fg; accent: sure ? Color.urgent : page.accent; fontFamily: page.ff
          onClicked: { if (!sure) { sure = true; return } page.mod.cmd(["unpair", card.modelData.id]); sure = false }
        }
      }
    }
  }

  SH.HubCard {
    width: page.width; height: help.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    Column {
      id: help
      x: SH.HubStyle.pad; y: SH.HubStyle.pad; width: parent.width - SH.HubStyle.pad * 2
      spacing: Style.space(8)
      SH.HubCaption { text: page.t("Новый телефон", "A new phone"); icon: "\u{f0415}"; fg: page.fg; fontFamily: page.ff }
      Text {
        width: parent.width; wrapMode: Text.Wrap
        text: page.t("Поставьте KDE Connect на телефон (есть для iPhone и Android), подключитесь к той же сети и выберите этот компьютер в приложении — здесь появится запрос, примите его.",
                     "Install KDE Connect on the phone (iPhone and Android), join the same network and pick this computer in the app — accept the request here.")
        color: Qt.darker(page.fg, 1.5); font.family: page.ff; font.pixelSize: Style.font.caption
      }
      SH.HubChip {
        icon: "\u{f0337}"; label: page.t("Принять запрос на сопряжение", "Accept a pairing request")
        fg: page.fg; accent: page.accent; fontFamily: page.ff
        onClicked: page.mod.cmd(["pair", "--yes"])
      }
    }
  }
}
