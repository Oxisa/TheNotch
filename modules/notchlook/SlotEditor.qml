import QtQuick
import qs.Commons
import "../../fonts"
import "../../vendor/soundhub" as SH

// What the collapsed notch shows, by dragging: a model of the notch with a
// left and a right side, and a pool of what isn't shown. Drop a chip on a
// side to add it there, on another chip to put it before that one, on the
// pool to hide it.
SH.HubCard {
  id: ed
  property var notch: null
  readonly property color accent: Color.accent
  readonly property string ff: Fonts.ui
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  fg: Color.foreground
  height: col.implicitHeight + SH.HubStyle.pad * 2

  readonly property var info: ({
    workspace: { icon: "\u{f0570}", ru: "Стол", en: "Workspace" },
    apps: { icon: "\u{f003b}", ru: "Приложения", en: "Apps" },
    shelf: { icon: "\u{f0120}", ru: "Полка", en: "Shelf" },
    weather: { icon: "\u{f0599}", ru: "Погода", en: "Weather" },
    clock: { icon: "\u{f0954}", ru: "Часы", en: "Clock" },
    layout: { icon: "\u{f030c}", ru: "Раскладка", en: "Keyboard layout" },
    privacy: { icon: "\u{f036c}", ru: "Кто слушает", en: "Mic/cam in use" },
    mic: { icon: "\u{f036d}", ru: "Микрофон выкл.", en: "Mic muted" }
  })
  readonly property var slots: notch ? notch.slots : ({ left: [], right: [] })
  readonly property var pool: notch ? notch.slotCatalog.filter(function(k) { return slots.left.indexOf(k) < 0 && slots.right.indexOf(k) < 0 }) : []
  // move `key` to `side` ("left", "right" or "pool"), before `before` when given
  function place(key, side, before) {
    var l = slots.left.filter(function(k) { return k !== key }), r = slots.right.filter(function(k) { return k !== key })
    if (side !== "pool") {
      var list = side === "left" ? l : r, i = before ? list.indexOf(before) : -1
      if (i < 0) list.push(key); else list.splice(i, 0, key)
    }
    notch.setSlots({ left: l, right: r })
  }

  component Chip: Rectangle {
    id: chip
    property string key: ""
    property string side: ""
    width: row.implicitWidth + Style.space(18); height: Style.space(28); radius: height / 2
    color: dropHere.containsDrag ? SH.HubStyle.tint(ed.accent, 0.45) : side === "pool" ? SH.HubStyle.tint(ed.fg, 0.08) : SH.HubStyle.tint(ed.accent, 0.22)
    opacity: ghost.Drag.active ? 0.35 : 1
    Row {
      id: row
      anchors.centerIn: parent
      spacing: Style.space(6)
      Text { text: ed.info[chip.key] ? ed.info[chip.key].icon : ""; color: ed.accent; font.family: ed.ff; font.pixelSize: Style.font.caption + 1 }
      Text { text: ed.info[chip.key] ? (ed.ru ? ed.info[chip.key].ru : ed.info[chip.key].en) : chip.key; color: ed.fg; font.family: ed.ff; font.pixelSize: Style.font.caption }
    }
    MouseArea {
      id: dm
      anchors.fill: parent
      cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
      drag.target: ghost
      drag.threshold: 4
      onReleased: if (ghost.Drag.active) ghost.Drag.drop()
    }
    DropArea {
      id: dropHere
      anchors.fill: parent
      keys: ["thenotch-slot"]
      onDropped: function(ev) { if (ev.source && ev.source.key !== chip.key) ed.place(ev.source.key, chip.side, chip.side === "pool" ? "" : chip.key) }
    }
    Rectangle {
      id: ghost
      readonly property string key: chip.key
      width: chip.width; height: chip.height; radius: chip.radius
      color: SH.HubStyle.tint(ed.accent, 0.5)
      border.width: 1; border.color: ed.accent
      visible: Drag.active
      z: 100
      Drag.active: dm.drag.active
      Drag.keys: ["thenotch-slot"]
      Drag.hotSpot.x: width / 2; Drag.hotSpot.y: height / 2
      Text { anchors.centerIn: parent; text: ed.info[chip.key] ? (ed.ru ? ed.info[chip.key].ru : ed.info[chip.key].en) : ""; color: ed.fg; font.family: ed.ff; font.pixelSize: Style.font.caption }
      onVisibleChanged: if (!visible) { x = 0; y = 0 }
    }
  }
  component Zone: Rectangle {
    id: zone
    property string side: "left"
    property alias items: rep.model
    property string placeholder: ""
    height: Math.max(Style.space(44), flow.implicitHeight + Style.space(16))
    radius: Style.space(14)
    color: zd.containsDrag ? SH.HubStyle.tint(ed.accent, 0.18) : "transparent"
    border.width: 1; border.color: SH.HubStyle.tint(ed.fg, zd.containsDrag ? 0.3 : 0.1)
    DropArea { id: zd; anchors.fill: parent; keys: ["thenotch-slot"]; onDropped: function(ev) { if (ev.source) ed.place(ev.source.key, zone.side, "") } }
    Text { visible: rep.count === 0; anchors.centerIn: parent; text: zone.placeholder; color: Qt.darker(ed.fg, 1.8); font.family: ed.ff; font.pixelSize: Style.font.caption - 1 }
    Flow {
      id: flow
      x: Style.space(8); y: Style.space(8)
      width: parent.width - Style.space(16)
      spacing: Style.space(6)
      Repeater { id: rep; delegate: Chip { required property string modelData; key: modelData; side: zone.side } }
    }
  }

  Column {
    id: col
    x: SH.HubStyle.pad; y: SH.HubStyle.pad
    width: parent.width - SH.HubStyle.pad * 2
    spacing: Style.space(10)
    SH.HubCaption { text: ed.t("Что показывать в чёлке", "What the notch shows"); icon: "\u{f0493}"; fg: ed.fg; fontFamily: ed.ff }
    // the notch: left side · the middle · right side
    Rectangle {
      width: parent.width; height: sides.height + Style.space(20)
      radius: Style.space(22)
      color: ed.notch ? ed.notch.islandColor : "black"
      Row {
        id: sides
        x: Style.space(10); y: Style.space(10)
        spacing: Style.space(10)
        Zone { width: (parent.parent.width - Style.space(20) - Style.space(10) * 2 - mid.width) / 2; side: "left"; items: ed.slots.left; placeholder: ed.t("Слева пусто", "Left: empty") }
        Item {
          id: mid
          width: Style.space(40); height: Style.space(44)
          Rectangle { anchors.centerIn: parent; width: Style.space(10); height: width; radius: width / 2; color: SH.HubStyle.tint(ed.fg, 0.25) }
        }
        Zone { width: (parent.parent.width - Style.space(20) - Style.space(10) * 2 - mid.width) / 2; side: "right"; items: ed.slots.right; placeholder: ed.t("Справа пусто", "Right: empty") }
      }
    }
    Text { text: ed.t("Не показывать", "Hidden"); color: Qt.darker(ed.fg, 1.4); font.family: ed.ff; font.pixelSize: Style.font.caption; font.bold: true }
    Zone { width: parent.width; side: "pool"; items: ed.pool; placeholder: ed.t("Всё показано — перетащите сюда лишнее", "All shown — drag here what you don't need") }
    Text {
      width: parent.width; wrapMode: Text.Wrap
      text: ed.t("Музыка, загрузка или таймер встают к середине, рядом с вашими элементами. «Кто слушает», «Микрофон выкл.», «Полка» и «Погода» видны, только когда есть что показать. Колесо мыши над столом листает столы, клик — обзор.",
                 "Music, a download or a timer sit next to the middle, beside your items. “Mic/cam in use”, “Mic muted”, “Shelf” and “Weather” show only when there's something to show. The wheel over the workspace flips workspaces, a click opens the overview.")
      color: Qt.darker(ed.fg, 1.6); font.family: ed.ff; font.pixelSize: Style.font.caption - 1
    }
  }
}
