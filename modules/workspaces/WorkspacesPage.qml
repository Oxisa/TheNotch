import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Commons
import "../../fonts"
import "../../vendor/soundhub" as SH

// The Spaces tab as a map: the monitors drawn where they really stand, each
// with its current workspace large (wallpaper + live windows) and a strip of
// its other workspaces under it. The tiling mode is one icon in a monitor's
// corner (a menu). Drag a window onto any workspace to move it there.
Item {
  id: page
  property var mod: null
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }
  Component.onCompleted: if (mod) mod.watchers += 1
  Component.onDestruction: if (mod) mod.watchers -= 1

  // ---- the layout in layout (logical) units, scaled to the page
  readonly property var mons: mod ? mod.monitors : []
  function lw(m) { return m.width / (m.scale || 1) }
  function lh(m) { return m.height / (m.scale || 1) }
  readonly property var box: {
    var x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9
    mons.forEach(function(m) { x0 = Math.min(x0, m.x); y0 = Math.min(y0, m.y); x1 = Math.max(x1, m.x + lw(m)); y1 = Math.max(y1, m.y + lh(m)) })
    return mons.length ? { x: x0, y: y0, w: x1 - x0, h: y1 - y0 } : { x: 0, y: 0, w: 1, h: 1 }
  }
  // rows of monitors (distinct tops), for the room each one's header and strip need
  readonly property var rows: { var r = []; mons.forEach(function(m) { if (r.indexOf(m.y) < 0) r.push(m.y) }); return r.sort(function(a, b) { return a - b }) }
  readonly property real gap: Style.space(14)
  readonly property real headH: Style.space(30)
  readonly property real stripH: Style.space(62)
  readonly property real k: Math.min((width - gap * 2) / box.w, Style.space(560) / box.h)
  implicitHeight: tip.height + Style.space(8) + box.h * k + rows.length * (headH + stripH + gap)
  width: parent ? parent.width : 860

  Item {
    id: tip
    width: page.width; height: Style.space(28)
    Text { anchors.verticalCenter: parent.verticalCenter; text: page.t("Перетащите окно на любой стол · колесо над чёлкой листает столы", "Drag a window onto any workspace · the wheel over the notch flips them"); color: Qt.darker(page.fg, 1.5); font.family: page.ff; font.pixelSize: Style.font.caption }
    SH.HubChip {
      anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
      icon: "\u{f0570}"; label: page.t("Весь экран  Super + `", "Full screen  Super + `")
      h: Style.space(26); subtle: true
      fg: page.fg; accent: page.accent; fontFamily: page.ff
      onClicked: { page.mod.notch.expanded = false; page.mod.overview = true }
    }
  }

  readonly property var modes: [
    { mode: "", icon: "\u{f0570}", label: page.t("Как везде", "Default") },
    { mode: "dwindle", icon: "\u{f0574}", label: page.t("Спираль", "Dwindle") },
    { mode: "master", icon: "\u{f056e}", label: page.t("Главное окно", "Master") },
    { mode: "scrolling", icon: "\u{f056d}", label: page.t("Лента", "Scrolling") },
    { mode: "floating", icon: "\u{f05b2}", label: page.t("Без тайлинга", "Floating") }
  ]
  function modeOf(m) { var id = mod.monitorMode(m); return modes.filter(function(x) { return x.mode === id })[0] || modes[0] }
  property string menuFor: ""                          // the monitor whose mode menu is open

  Repeater {
    model: page.mons
    delegate: Item {
      id: mon
      required property var modelData
      readonly property int row: page.rows.indexOf(modelData.y)
      readonly property var cur: modelData.activeWorkspace
      readonly property var others: page.mod.workspacesOn(modelData).filter(function(w) { return !mon.cur || w.id !== mon.cur.id })
      x: page.gap + (modelData.x - page.box.x) * page.k
      y: tip.height + Style.space(8) + (modelData.y - page.box.y) * page.k + row * (page.headH + page.stripH + page.gap)
      width: page.lw(modelData) * page.k - page.gap
      height: page.headH + page.lh(modelData) * page.k + page.stripH
      z: page.menuFor === modelData.name ? 20 : 1

      // header: name · workspace, the mode icon
      Item {
        id: head
        width: parent.width; height: page.headH
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: mon.modelData.name + (mon.cur ? "  ·  " + mon.cur.id + (page.mod.nameOf(mon.cur) ? " " + page.mod.nameOf(mon.cur) : "") : "")
          color: mon.modelData.focused ? page.accent : page.fg; font.family: page.ff; font.pixelSize: Style.font.caption + 1; font.bold: true
        }
        Rectangle {
          id: modeBtn
          anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
          width: modeRow.implicitWidth + Style.space(16); height: Style.space(24); radius: height / 2
          color: SH.HubStyle.tint(page.fg, mm.containsMouse || page.menuFor === mon.modelData.name ? 0.14 : 0.07)
          Row {
            id: modeRow
            anchors.centerIn: parent
            spacing: Style.space(5)
            Text { anchors.verticalCenter: parent.verticalCenter; text: page.modeOf(mon.modelData).icon; color: page.accent; font.family: page.ff; font.pixelSize: Style.font.caption + 1 }
            Text { anchors.verticalCenter: parent.verticalCenter; text: page.modeOf(mon.modelData).label; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption - 1 }
            Text { anchors.verticalCenter: parent.verticalCenter; text: "\u{f0140}"; color: Qt.darker(page.fg, 1.4); font.family: page.ff; font.pixelSize: Style.font.caption - 1 }
          }
          MouseArea { id: mm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.menuFor = page.menuFor === mon.modelData.name ? "" : mon.modelData.name }
        }
      }

      // the current workspace, large
      WsCard {
        id: big
        y: page.headH
        width: parent.width
        mod: page.mod; ws: mon.cur; monitor: mon.modelData
        live: page.visible
        showLabel: false
      }

      // the monitor's other workspaces + a new one
      Row {
        y: page.headH + page.lh(mon.modelData) * page.k + Style.space(8)
        spacing: Style.space(8)
        Repeater {
          model: mon.others
          delegate: WsCard {
            required property var modelData
            width: Math.round((page.stripH - Style.space(22)) * page.lw(mon.modelData) / page.lh(mon.modelData))
            mod: page.mod; ws: modelData; monitor: mon.modelData
            live: page.visible
          }
        }
        Rectangle {
          width: Style.space(40); height: page.stripH - Style.space(22)
          radius: Style.space(8)
          color: SH.HubStyle.tint(page.fg, addM.containsMouse ? 0.14 : 0.06)
          Text { anchors.centerIn: parent; text: "\u{f0415}"; color: page.accent; font.family: page.ff; font.pixelSize: Style.space(16) }
          MouseArea { id: addM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.mod.newOn(mon.modelData) }
        }
      }

      // the mode menu
      Rectangle {
        visible: page.menuFor === mon.modelData.name
        anchors.right: parent.right; y: page.headH + Style.space(2)
        width: Style.space(240); height: menuCol.implicitHeight + Style.space(12)
        radius: Style.space(12)
        color: Color.background
        border.width: 1; border.color: SH.HubStyle.tint(page.fg, 0.15)
        Column {
          id: menuCol
          x: Style.space(6); y: Style.space(6)
          width: parent.width - Style.space(12)
          Repeater {
            model: page.modes
            delegate: Rectangle {
              required property var modelData
              readonly property bool on: page.mod.monitorMode(mon.modelData) === modelData.mode
              width: menuCol.width; height: Style.space(30); radius: Style.space(8)
              color: im.containsMouse ? SH.HubStyle.tint(page.fg, 0.1) : on ? SH.HubStyle.tint(page.accent, 0.18) : "transparent"
              Text { x: Style.space(10); anchors.verticalCenter: parent.verticalCenter; text: modelData.icon + "   " + modelData.label; color: parent.on ? page.accent : page.fg; font.family: page.ff; font.pixelSize: Style.font.caption + 1 }
              MouseArea { id: im; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { page.mod.setMonitorMode(mon.modelData, modelData.mode); if (modelData.mode !== "floating") page.menuFor = "" } }
            }
          }
          // without tiling: the snap layout for Super + Shift + drag
          Text { visible: page.mod.monitorMode(mon.modelData) === "floating"; topPadding: Style.space(6); leftPadding: Style.space(10); text: page.t("Зоны (Super + Shift + перетаскивание)", "Zones (Super + Shift + drag)"); color: Qt.darker(page.fg, 1.4); font.family: page.ff; font.pixelSize: Style.font.caption - 1 }
          Flow {
            visible: page.mod.monitorMode(mon.modelData) === "floating"
            width: menuCol.width; leftPadding: Style.space(8); topPadding: Style.space(4); bottomPadding: Style.space(4)
            spacing: Style.space(6)
            Repeater {
              model: ["halves", "thirds", "quarters", "main", "wide"]
              delegate: Rectangle {
                id: lay
                required property string modelData
                readonly property bool on: page.mod.snapLayoutOf(mon.modelData) === modelData
                width: Style.space(38); height: Style.space(24); radius: Style.space(5)
                color: SH.HubStyle.tint(page.fg, lm.containsMouse ? 0.12 : 0.05)
                border.width: on ? 2 : 1; border.color: on ? page.accent : SH.HubStyle.tint(page.fg, 0.12)
                Repeater {
                  model: page.mod.snapLayouts[lay.modelData]
                  delegate: Rectangle {
                    required property var modelData
                    x: 3 + modelData[0] * (lay.width - 6) + 1; y: 3 + modelData[1] * (lay.height - 6) + 1
                    width: modelData[2] * (lay.width - 6) - 2; height: modelData[3] * (lay.height - 6) - 2
                    radius: 2; color: lay.on ? SH.HubStyle.tint(page.accent, 0.6) : SH.HubStyle.tint(page.fg, 0.22)
                  }
                }
                MouseArea { id: lm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.mod.setSnapLayout(mon.modelData, lay.modelData) }
              }
            }
          }
        }
      }
    }
  }
}
