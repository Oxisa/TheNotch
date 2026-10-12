import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import "../../fonts"
import "../../vendor/soundhub" as SH

// The full-screen overview on one monitor (Super + `): the monitor's
// workspaces along the top, the current one large in the middle with its
// windows live. Click a window to go to it, drag it onto a workspace up top
// to move it there; Esc or a click on the empty space closes.
PanelWindow {
  id: ov
  property var mod: null
  readonly property var hmon: mod ? mod.monitors.filter(function(m) { return m.name === (ov.screen ? ov.screen.name : "") })[0] || null : null
  readonly property var cur: hmon ? hmon.activeWorkspace : null
  color: "transparent"
  anchors { top: true; bottom: true; left: true; right: true }
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "osia-thenotch-overview"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: hmon && hmon.focused ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property string ff: Fonts.ui
  function close() { if (mod) mod.overview = false }

  Rectangle {
    id: dim
    anchors.fill: parent
    color: Qt.rgba(Color.background.r, Color.background.g, Color.background.b, 0.82)
    opacity: 0
    Component.onCompleted: opacity = 1
    Behavior on opacity { NumberAnimation { duration: 180 } }
    focus: true
    Keys.onEscapePressed: ov.close()
    MouseArea { anchors.fill: parent; onClicked: ov.close() }

    // workspaces of this monitor
    Row {
      id: top
      anchors.horizontalCenter: parent.horizontalCenter
      y: Style.space(28)
      spacing: Style.space(14)
      Repeater {
        model: ov.mod && ov.hmon ? ov.mod.workspacesOn(ov.hmon) : []
        delegate: WsCard {
          required property var modelData
          width: Style.space(210)
          mod: ov.mod; ws: modelData; monitor: ov.hmon
          onPicked: ov.close()
        }
      }
      Rectangle {
        width: Style.space(70); height: Math.round(Style.space(210) * (ov.hmon ? ov.hmon.height / Math.max(1, ov.hmon.width) : 0.56))
        radius: Style.space(8)
        color: SH.HubStyle.tint(ov.fg, addM.containsMouse ? 0.14 : 0.06)
        Text { anchors.centerIn: parent; text: "\u{f0415}"; color: ov.accent; font.family: ov.ff; font.pixelSize: Style.space(24) }
        MouseArea { id: addM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { ov.mod.newOn(ov.hmon); ov.close() } }
      }
    }

    // the current workspace, large
    WsCard {
      id: main
      big: true
      mod: ov.mod; ws: ov.cur; monitor: ov.hmon
      readonly property real room: ov.height - top.y - top.height - Style.space(110)
      width: Math.min(ov.width * 0.82, room * (ov.hmon ? ov.hmon.width / Math.max(1, ov.hmon.height) : 1.78))
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: top.bottom; anchors.topMargin: Style.space(40)
      onPicked: ov.close()
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom; anchors.bottomMargin: Style.space(24)
      text: (ov.cur ? (ov.mod.nameOf(ov.cur) || ov.mod.t("Стол ", "Workspace ") + ov.cur.id) + "   ·   " : "") + ov.mod.t("Esc — закрыть · перетащите окно на стол сверху", "Esc closes · drag a window onto a workspace above")
      color: Qt.darker(ov.fg, 1.4); font.family: ov.ff; font.pixelSize: Style.font.caption
    }
  }
}
