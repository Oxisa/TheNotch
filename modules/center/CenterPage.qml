import QtQuick
import qs.Commons
import "../../../osia.soundhub" as SH
import "../home"

// Centre's page: notifications on the left (the Notifications module's own
// page), quick toggles and the timer on the right.
Row {
  id: page
  property var mod: null
  spacing: Style.space(12)
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property string ff: Style.font.family
  readonly property var notif: mod ? mod.notif : null
  readonly property real rightW: Style.space(360)
  height: Math.max(left.implicitHeight, right.implicitHeight)

  Item {
    id: left
    width: page.width - page.rightW - page.spacing
    implicitHeight: notifLoader.item ? Math.min(Style.space(560), notifLoader.item.implicitHeight) : Style.space(80)
    height: Math.max(implicitHeight, right.implicitHeight)
    clip: true
    Flickable {
      anchors.fill: parent
      contentHeight: notifLoader.item ? notifLoader.item.implicitHeight : 0
      interactive: contentHeight > height
      boundsBehavior: Flickable.StopAtBounds
      Loader {
        id: notifLoader
        width: left.width
        active: !!(page.notif && page.notif.active && page.notif.page)
        sourceComponent: page.notif ? page.notif.page : null
      }
    }
  }

  Column {
    id: right
    width: page.rightW
    spacing: Style.space(10)
    Grid {
      columns: 2
      spacing: Style.space(6)
      Repeater {
        model: page.mod ? page.mod.toggles : []
        delegate: Rectangle {
          id: tile
          required property var modelData
          width: (page.rightW - Style.space(6)) / 2
          height: Style.space(50)
          radius: SH.HubStyle.radiusSmall + Style.space(2)
          color: modelData.on ? SH.HubStyle.tint(page.accent, tm.containsMouse ? 0.42 : 0.30)
                              : SH.HubStyle.tint(page.fg, tm.containsMouse ? 0.10 : 0.05)
          Behavior on color { ColorAnimation { duration: 150 } }
          Row {
            anchors.verticalCenter: parent.verticalCenter
            x: Style.space(12)
            width: parent.width - Style.space(18)
            spacing: Style.space(10)
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: tile.modelData.icon
              color: tile.modelData.on ? page.accent : page.fg
              font.family: page.ff; font.pixelSize: Style.space(18)
            }
            Column {
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width - Style.space(32)
              Text { width: parent.width; elide: Text.ElideRight; text: tile.modelData.label; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption; font.bold: true }
              Text { width: parent.width; elide: Text.ElideRight; text: tile.modelData.sub; color: Qt.darker(page.fg, 1.5); font.family: page.ff; font.pixelSize: Style.font.caption - 2 }
            }
          }
          MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.mod.toggle(tile.modelData.id) }
        }
      }
    }
    Rectangle {
      width: page.rightW
      height: timer.implicitHeight + Style.space(24)
      radius: SH.HubStyle.radius + Style.space(2)
      color: SH.HubStyle.tint(page.fg, 0.05)
      TimerCard { id: timer; anchors.centerIn: parent; mod: page.mod }
    }
  }
}
