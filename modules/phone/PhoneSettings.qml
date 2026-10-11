import QtQuick
import Quickshell
import qs.Commons
import "../../../osia.soundhub" as SH

// Settings → Bluetooth & devices → Phone: the AirPlay receiver for an
// iPhone's screen — on/off, how to connect, name, PIN, full screen, the
// firewall line to run once.
Column {
  id: page
  property var mod: null
  spacing: SH.HubStyle.gap
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Style.font.family
  function t(a, b) { return mod ? mod.t(a, b) : b }
  readonly property string ufw: "sudo ufw allow from 192.168.0.0/16 to any port 7000,7001,7100 proto tcp && sudo ufw allow from 192.168.0.0/16 to any port 6000,6001,7011 proto udp && sudo ufw allow from 192.168.0.0/16 to any port 5353 proto udp"

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

  Card {
    SH.HubRow {
      icon: "\u{f011c}"
      title: page.t("Экран iPhone на компьютере", "iPhone screen on this computer")
      hint: !page.mod || !page.mod.installed ? page.t("Нужен приёмник AirPlay (UxPlay) — соберу для вашего пользователя, без пароля", "Needs an AirPlay receiver (UxPlay) — builds for your user, no password")
            : page.mod.status === "mirroring" ? page.t("Идёт повтор экрана", "Mirroring") + (page.mod.client ? " · " + page.mod.client : "")
            : page.mod.status === "waiting" ? page.t("Ждёт iPhone: «", "Waiting: “") + page.mod.name + page.t("» в Повторе экрана", "” in Screen Mirroring")
            : page.t("Выключен", "Off")
      fg: page.fg; fontFamily: page.ff
      Row {
        spacing: Style.space(6)
        SH.HubChip {
          visible: page.mod && !page.mod.installed
          icon: page.mod && page.mod.installing ? "\u{f051f}" : "\u{f01da}"
          label: page.mod && page.mod.installing ? page.t("Собираю…", "Building…") : page.t("Установить", "Install")
          on: true
          fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
          onClicked: if (!page.mod.installing) page.mod.install()
        }
        SH.HubSwitch {
          visible: page.mod && page.mod.installed
          checked: page.mod ? page.mod.status !== "off" : false
          fg: page.fg; accent: page.accent; ink: page.bgc
          onToggled: checked ? page.mod.stop() : page.mod.start()
        }
      }
    }
    Text {
      width: parent.width; wrapMode: Text.Wrap
      text: page.t("На iPhone: Пункт управления → «Повтор экрана» → «", "On the iPhone: Control Centre → Screen Mirroring → “") + (page.mod ? page.mod.name : "") + page.t("». Оба устройства — в одной сети.", "”. Both on the same network.")
      color: Qt.darker(page.fg, 1.3); font.family: page.ff; font.pixelSize: Style.font.caption
    }
  }
  Card {
    SH.HubRow {
      title: page.t("Имя для iPhone", "Name on the iPhone"); fg: page.fg; fontFamily: page.ff
      SH.HubField {
        width: Style.space(200)
        placeholderText: page.mod ? page.mod.name : ""
        text: page.mod ? String(page.mod.opt("name", "")) : ""
        fg: page.fg; accent: page.accent; fontFamily: page.ff
        onEditingFinished: page.mod.persist({ name: text.trim() })
      }
    }
    SH.HubRow {
      title: page.t("PIN-код", "PIN code"); hint: page.t("4 цифры, их спросит iPhone; пусто — без кода", "4 digits the iPhone asks for; empty — none"); fg: page.fg; fontFamily: page.ff
      SH.HubField {
        width: Style.space(120)
        placeholderText: "1234"
        text: page.mod ? page.mod.pin : ""
        fg: page.fg; accent: page.accent; fontFamily: page.ff
        onEditingFinished: { var p = text.replace(/\D/g, "").slice(0, 4); page.mod.persist({ pin: p.length === 4 ? p : "" }) }
      }
    }
    SH.HubRow {
      title: page.t("Во весь экран", "Full screen"); fg: page.fg; fontFamily: page.ff
      SH.HubSwitch { checked: page.mod ? page.mod.opt("fullscreen", false) === true : false; fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.mod.persist({ fullscreen: !checked }) }
    }
    SH.HubRow {
      title: page.t("Звук с телефона", "Phone's sound"); fg: page.fg; fontFamily: page.ff
      SH.HubSwitch { checked: page.mod ? page.mod.opt("audio", true) !== false : true; fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.mod.persist({ audio: !checked }) }
    }
    Text {
      width: parent.width; wrapMode: Text.Wrap
      text: page.t("Изменения применятся при следующем включении.", "Changes apply the next time it starts.")
      color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption - 1
    }
  }
  Card {
    SH.HubCaption { text: page.t("Если iPhone не видит компьютер", "If the iPhone doesn't see the computer"); icon: "\u{f099d}"; fg: page.fg; fontFamily: page.ff }
    Text {
      width: parent.width; wrapMode: Text.Wrap
      text: page.t("Включён фаервол (ufw). Один раз откройте порты AirPlay для домашней сети — команда спросит пароль:",
                   "The firewall (ufw) is on. Open the AirPlay ports for your home network once — it asks for your password:")
      color: Qt.darker(page.fg, 1.3); font.family: page.ff; font.pixelSize: Style.font.caption
    }
    Rectangle {
      width: parent.width; height: cmd.implicitHeight + Style.space(16)
      radius: Style.space(8); color: SH.HubStyle.tint(page.fg, 0.06)
      Text { id: cmd; x: Style.space(10); y: Style.space(8); width: parent.width - Style.space(20); wrapMode: Text.WrapAnywhere; text: page.ufw; color: page.fg; font.family: "monospace"; font.pixelSize: Style.font.caption - 1 }
    }
    SH.HubChip {
      property bool done: false
      icon: done ? "󰄬" : "󰆏"; label: done ? page.t("Скопировано", "Copied") : page.t("Скопировать команду", "Copy the command")
      fg: page.fg; accent: page.accent; fontFamily: page.ff
      onClicked: { Quickshell.execDetached(["wl-copy", page.ufw]); done = true }
    }
  }
}
