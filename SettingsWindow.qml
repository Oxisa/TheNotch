import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.Commons
import "../osia.soundhub" as SH

// TheNotch's settings window: one card in the middle of the focused screen
// over a dimmed desktop. Sections on the left — TheNotch itself and every
// module that has a settingsPage — and the chosen section's settings on the
// right, so the notch's dashboards stay free of settings.
// Esc, the × or a click on the dimmed area closes it.
PanelWindow {
  id: win
  property var notch: null

  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Style.font.family
  readonly property var sections: notch ? notch.settingsModules : []
  readonly property var current: {
    for (var i = 0; i < sections.length; i++) if (sections[i].moduleId === notch.settingsSection) return sections[i]
    return sections.length ? sections[0] : null
  }

  color: "transparent"
  anchors { top: true; bottom: true; left: true; right: true }
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "osia-thenotch-settings"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

  function close() { if (notch) notch.settingsOpen = false }
  readonly property bool ru: notch !== null && notch.lang === "ru"

  // a switched-off module's section: say so, offer to switch it on
  Component {
    id: offPage
    Column {
      spacing: Style.space(14)
      topPadding: Style.space(30)
      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: win.current ? win.current.icon : ""
        color: Qt.darker(win.fg, 1.8)
        font.family: win.ff; font.pixelSize: Style.space(40)
      }
      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: win.ru ? "Модуль выключен. Включите его, чтобы настроить."
                     : "This module is off. Turn it on to set it up."
        color: Qt.darker(win.fg, 1.4)
        font.family: win.ff; font.pixelSize: Style.font.body
      }
      SH.HubChip {
        anchors.horizontalCenter: parent.horizontalCenter
        icon: "\u{f0425}"
        label: win.ru ? "Включить модуль" : "Turn the module on"
        on: true
        fg: win.fg; accent: win.accent; ink: win.bgc; fontFamily: win.ff
        onClicked: win.notch.setModuleEnabled(win.current.moduleId, true)
      }
    }
  }

  // dimmed backdrop; a click outside the card closes
  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.38)
    opacity: 0
    Component.onCompleted: opacity = 1
    Behavior on opacity { NumberAnimation { duration: 180 } }
    MouseArea { anchors.fill: parent; onClicked: win.close() }
  }

  Rectangle {
    id: card
    anchors.centerIn: parent
    width: Math.min(parent.width - Style.space(60), Style.space(820))
    height: Math.min(parent.height - Style.space(80), Style.space(600))
    radius: SH.HubStyle.radius + Style.space(6)
    color: win.bgc
    border.width: 1
    border.color: SH.HubStyle.tint(win.fg, 0.10)
    scale: 0.96; opacity: 0
    Component.onCompleted: { scale = 1; opacity = 1 }
    Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 180 } }
    MouseArea { anchors.fill: parent }                 // clicks on the card stay on it

    focus: true
    Keys.onEscapePressed: win.close()
    Component.onDestruction: {}

    // ------------------------------------------------------ sidebar
    Rectangle {
      id: side
      x: Style.space(10); y: Style.space(10)
      width: Style.space(210); height: parent.height - Style.space(20)
      radius: SH.HubStyle.radius
      color: SH.HubStyle.tint(win.fg, SH.HubStyle.surface)

      Column {
        x: Style.space(10); y: Style.space(14)
        width: parent.width - Style.space(20)
        spacing: Style.space(4)

        Text {
          leftPadding: Style.space(8); bottomPadding: Style.space(10)
          text: "󰒓  " + (win.notch ? win.notch.t("settingsTitle") : "")
          color: win.fg
          font.family: win.ff; font.pixelSize: Style.font.title; font.bold: true
        }
        Repeater {
          model: win.sections
          delegate: Rectangle {
            id: item
            required property var modelData
            readonly property bool on: win.current === modelData
            width: parent.width
            height: Style.space(38)
            radius: height / 2
            color: on ? win.accent : SH.HubStyle.tint(win.fg, itemMouse.containsMouse ? SH.HubStyle.controlHover : 0)
            opacity: item.modelData.active ? 1 : 0.5            // a switched-off module
            Behavior on color { ColorAnimation { duration: 160 } }
            Row {
              anchors.verticalCenter: parent.verticalCenter
              x: Style.space(14)
              spacing: Style.space(10)
              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: item.modelData.icon
                color: item.on ? win.bgc : win.fg
                font.family: win.ff; font.pixelSize: Style.font.body + 1
              }
              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: item.modelData.title
                color: item.on ? win.bgc : win.fg
                font.family: win.ff; font.pixelSize: Style.font.body; font.bold: item.on
              }
            }
            MouseArea {
              id: itemMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: win.notch.settingsSection = item.modelData.moduleId
            }
          }
        }
      }
    }

    // ------------------------------------------------------ content
    Item {
      id: main
      anchors.left: side.right; anchors.leftMargin: Style.space(16)
      anchors.right: parent.right; anchors.rightMargin: Style.space(16)
      anchors.top: parent.top; anchors.topMargin: Style.space(16)
      anchors.bottom: parent.bottom; anchors.bottomMargin: Style.space(12)

      Text {
        id: heading
        text: win.current ? win.current.title : ""
        color: win.fg
        font.family: win.ff; font.pixelSize: Style.font.title + 2; font.bold: true
      }
      SH.HubChip {
        anchors.right: parent.right
        anchors.verticalCenter: heading.verticalCenter
        iconOnly: true
        icon: "󰅖"
        label: "Esc"
        fg: win.fg; accent: win.accent; fontFamily: win.ff
        onClicked: win.close()
      }

      Flickable {
        id: flick
        anchors.top: heading.bottom; anchors.topMargin: Style.space(14)
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        contentWidth: width
        contentHeight: pageLoader.item ? pageLoader.item.implicitHeight + Style.space(8) : 0
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        Loader {
          id: pageLoader
          width: flick.width - Style.space(10)
          sourceComponent: !win.current ? null : win.current.active ? win.current.settingsPage : offPage
          onLoaded: flick.contentY = 0
        }
      }
    }
  }
}
