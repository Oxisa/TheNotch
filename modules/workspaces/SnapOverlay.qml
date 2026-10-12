import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

// The snap zones over one monitor while a window is dragged with
// Super + Shift (like Windows' snap layouts / FancyZones): the monitor's
// layout drawn as frames, the one under the cursor lit. Takes no input —
// the drag stays Hyprland's; the module snaps on release.
PanelWindow {
  id: so
  property var mod: null
  property var hmon: null
  color: "transparent"
  anchors { top: true; bottom: true; left: true; right: true }
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "osia-thenotch-snap"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  mask: Region {}
  readonly property var zones: mod && hmon ? mod.zonesFor(hmon) : []
  readonly property real ox: hmon ? hmon.x : 0
  readonly property real oy: hmon ? hmon.y : 0

  Repeater {
    model: so.zones
    delegate: Rectangle {
      required property var modelData
      required property int index
      readonly property bool lit: so.mod && so.mod.snapZone && so.mod.snapZone.mon === so.hmon.name && so.mod.snapZone.i === index
      x: modelData.x - so.ox; y: modelData.y - so.oy; width: modelData.w; height: modelData.h
      radius: Style.space(14)
      color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, lit ? 0.32 : 0.08)
      border.width: lit ? 3 : 2
      border.color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, lit ? 1 : 0.45)
      Behavior on color { ColorAnimation { duration: 120 } }
      Text { anchors.centerIn: parent; text: index + 1; color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, lit ? 0.9 : 0.35); font.pixelSize: Math.min(parent.height, parent.width) * 0.18; font.bold: true }
    }
  }
}
