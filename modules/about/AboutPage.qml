import QtQuick
import Quickshell
import qs.Commons
import "../../../osia.soundhub" as SH

// Settings → About: what this computer is, copyable in one click.
SH.HubCard {
  id: page
  property var mod: null
  width: parent ? parent.width : 400
  height: col.implicitHeight + SH.HubStyle.pad * 2
  fg: Color.foreground; accent: Color.accent
  readonly property string ff: Style.font.family
  function t(a, b) { return mod ? mod.t(a, b) : b }
  Component.onCompleted: if (mod) mod.load()
  readonly property var rows: [
    { k: "host", l: page.t("Имя компьютера", "Device name") }, { k: "os", l: page.t("Система", "System") },
    { k: "omarchy", l: "Omarchy" }, { k: "hyprland", l: "Hyprland" }, { k: "kernel", l: page.t("Ядро", "Kernel") },
    { k: "cpu", l: page.t("Процессор", "Processor") }, { k: "gpu", l: page.t("Видеокарта", "Graphics") },
    { k: "ram", l: page.t("Память", "Memory") }, { k: "disk", l: page.t("Диск /", "Disk /") }, { k: "board", l: page.t("Плата", "Board") }]
  Column {
    id: col
    x: SH.HubStyle.pad; y: SH.HubStyle.pad
    width: parent.width - SH.HubStyle.pad * 2
    spacing: Style.space(8)
    Repeater {
      model: page.rows
      delegate: Item {
        required property var modelData
        readonly property string v: page.mod && page.mod.info[modelData.k] ? page.mod.info[modelData.k] : ""
        visible: v !== ""
        width: parent.width; height: visible ? Math.max(Style.space(22), vt.implicitHeight) : 0
        Text { text: modelData.l; color: Qt.darker(page.fg, 1.4); font.family: page.ff; font.pixelSize: Style.font.caption + 1 }
        Text { id: vt; anchors.right: parent.right; width: parent.width * 0.65; horizontalAlignment: Text.AlignRight; wrapMode: Text.Wrap; text: parent.v; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption + 1 }
      }
    }
    SH.HubChip {
      property bool done: false
      icon: done ? "󰄬" : "󰆏"
      label: done ? page.t("Скопировано", "Copied") : page.t("Скопировать сведения", "Copy the details")
      fg: page.fg; accent: page.accent; fontFamily: page.ff
      onClicked: {
        var s = []
        for (var i = 0; i < page.rows.length; i++) { var v = page.mod.info[page.rows[i].k]; if (v) s.push(page.rows[i].l + ": " + v) }
        Quickshell.execDetached(["wl-copy", s.join("\n")]); done = true
      }
    }
  }
}
