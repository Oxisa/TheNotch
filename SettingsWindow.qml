import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.Commons
import "vendor/soundhub" as SH
import "Sections.js" as Sections
import "fonts"

// TheNotch's settings window, organised like Windows Settings: fixed
// sections on the left (System, Network & internet, Bluetooth & devices,
// Displays, Sound, Input, Personalisation, Account, Apps, Modules, Omarchy
// plugins, About). Modules don't get sections of their own — each puts its
// settings into one of them (`settingsSection`); a section with several
// parts shows them as tabs, one at a time. Every setting of a section is
// always shown — there is no Basic / Advanced split.
// Esc, the × or a click outside closes it.
PanelWindow {
  id: win
  property var notch: null

  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  readonly property bool ru: notch !== null && notch.lang === "ru"

  function partsOf(id) {
    var ms = notch ? notch.settingsModules : []
    return ms.filter(function(m) { return m.settingsSection === id })
             .sort(function(a, b) { return a.sectionOrder - b.sectionOrder })
  }
  readonly property var sections: Sections.SECTIONS.filter(function(s) { return win.partsOf(s.id).length > 0 })
  readonly property var current: {
    var want = notch ? notch.settingsSection : ""
    for (var i = 0; i < sections.length; i++) if (sections[i].id === want) return sections[i]
    return sections.length ? sections[0] : null
  }
  readonly property var parts: current ? partsOf(current.id) : []
  // the open tab in a section with several parts (by module id)
  property var tabOf: ({})
  readonly property var part: {
    if (!parts.length) return null
    var want = notch && notch.settingsFocus ? notch.settingsFocus : (current ? (tabOf[current.id] || savedTabs[current.id] || "") : "")
    for (var i = 0; i < parts.length; i++) if (parts[i].moduleId === want) return parts[i]
    return parts[0]
  }
  function openTab(m) { var o = Object.assign({}, tabOf); o[current.id] = m.moduleId; tabOf = o; if (notch) notch.settingsFocus = "" }
  // remember the section and its tab for the next time; the window reads a
  // copy taken when it opens, so saving doesn't loop back into `part`
  property var savedTabs: ({})
  onVisibleChanged: if (visible && notch) savedTabs = JSON.parse(JSON.stringify(notch.settingsTabs))
  Component.onCompleted: if (notch) savedTabs = JSON.parse(JSON.stringify(notch.settingsTabs))
  onPartChanged: if (notch && current && part && visible) { var c = current.id, m = part.moduleId; Qt.callLater(function() { notch.rememberTab(c, m) }) }

  color: "transparent"
  anchors { top: true; bottom: true; left: true; right: true }
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "osia-thenotch-settings"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

  function close() { if (notch) notch.settingsOpen = false }
  function title(s) { return ru ? s.ru : s.en }

  // a switched-off module's part: say so, offer to switch it on
  component OffPart: Row {
    property var module: null
    spacing: Style.space(12)
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: win.ru ? "Модуль выключен." : "This module is off."
      color: Qt.darker(win.fg, 1.4)
      font.family: win.ff; font.pixelSize: Style.font.body
    }
    SH.HubChip {
      icon: "\u{f0425}"
      label: win.ru ? "Включить" : "Turn on"
      on: true
      fg: win.fg; accent: win.accent; ink: win.bgc; fontFamily: win.ff
      onClicked: win.notch.setModuleEnabled(parent.module.moduleId, true)
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
    width: Math.min(parent.width - Style.space(60), Style.space(1000))
    height: Math.min(parent.height - Style.space(80), Style.space(700))
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

    // ------------------------------------------------------ sidebar
    Rectangle {
      id: side
      x: Style.space(10); y: Style.space(10)
      width: Style.space(236); height: parent.height - Style.space(20)
      radius: SH.HubStyle.radius
      color: SH.HubStyle.tint(win.fg, SH.HubStyle.surface)

      Flickable {
        anchors.fill: parent
        anchors.margins: Style.space(10)
        contentHeight: sideCol.implicitHeight
        clip: true
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        Column {
          id: sideCol
          width: parent.width
          spacing: Style.space(3)
          Text {
            leftPadding: Style.space(8); topPadding: Style.space(4); bottomPadding: Style.space(10)
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
                  text: win.title(item.modelData)
                  color: item.on ? win.bgc : win.fg
                  font.family: win.ff; font.pixelSize: Style.font.body; font.bold: item.on
                }
              }
              MouseArea {
                id: itemMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { win.notch.settingsSection = item.modelData.id; win.notch.settingsFocus = "" }
              }
            }
          }
        }
      }
    }

    // ------------------------------------------------------ content
    Item {
      id: main
      anchors.left: side.right; anchors.leftMargin: Style.space(18)
      anchors.right: parent.right; anchors.rightMargin: Style.space(16)
      anchors.top: parent.top; anchors.topMargin: Style.space(16)
      anchors.bottom: parent.bottom; anchors.bottomMargin: Style.space(12)

      Text {
        id: heading
        text: win.current ? win.title(win.current) : ""
        color: win.fg
        font.family: win.ff; font.pixelSize: Style.font.title + 2; font.bold: true
      }
      Row {
        anchors.right: parent.right
        anchors.verticalCenter: heading.verticalCenter
        spacing: Style.space(10)
        SH.HubChip {
          anchors.verticalCenter: parent.verticalCenter
          iconOnly: true
          icon: "󰅖"
          label: "Esc"
          fg: win.fg; accent: win.accent; fontFamily: win.ff
          onClicked: win.close()
        }
      }

      // the parts of this section as tabs
      Flickable {
        id: tabsBar
        visible: win.parts.length > 1
        anchors.top: heading.bottom; anchors.topMargin: Style.space(14)
        anchors.left: parent.left; anchors.right: parent.right
        height: visible ? Style.space(34) : 0
        contentWidth: tabsRow.implicitWidth
        clip: true
        interactive: contentWidth > width
        boundsBehavior: Flickable.StopAtBounds
        Row {
          id: tabsRow
          spacing: Style.space(6)
          Repeater {
            model: win.parts
            delegate: Rectangle {
              id: tb
              required property var modelData
              readonly property bool on: win.part === modelData
              height: Style.space(32)
              width: tbRow.implicitWidth + Style.space(26)
              radius: height / 2
              color: on ? win.accent : SH.HubStyle.tint(win.fg, tbm.containsMouse ? 0.10 : 0.05)
              opacity: modelData.active ? 1 : 0.55
              Behavior on color { ColorAnimation { duration: 140 } }
              Row {
                id: tbRow
                anchors.centerIn: parent
                spacing: Style.space(7)
                Text { anchors.verticalCenter: parent.verticalCenter; text: tb.modelData.icon; color: tb.on ? win.bgc : win.accent; font.family: win.ff; font.pixelSize: Style.font.body }
                Text { anchors.verticalCenter: parent.verticalCenter; text: tb.modelData.title; color: tb.on ? win.bgc : win.fg; font.family: win.ff; font.pixelSize: Style.font.body; font.bold: tb.on }
              }
              MouseArea { id: tbm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.openTab(tb.modelData) }
            }
          }
        }
      }

      Flickable {
        id: flick
        anchors.top: tabsBar.visible ? tabsBar.bottom : heading.bottom; anchors.topMargin: Style.space(16)
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        contentWidth: width
        contentHeight: partCol.implicitHeight + Style.space(8)
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        Column {
          id: partCol
          width: flick.width - Style.space(10)
          spacing: Style.space(12)
          Text {
            visible: !!(win.part && win.part.description) && win.parts.length > 1
            width: parent.width; wrapMode: Text.Wrap
            text: win.part ? win.part.description : ""
            color: Qt.darker(win.fg, 1.5); font.family: win.ff; font.pixelSize: Style.font.caption
          }
          OffPart { visible: !!(win.part && !win.part.active); module: win.part }
          Loader {
            id: pl
            width: parent.width
            active: !!(win.part && win.part.active)
            sourceComponent: win.part ? win.part.settingsPage : null
            onLoaded: {
              flick.contentY = 0
            }
          }
        }
      }
    }
  }
  onCurrentChanged: flick.contentY = 0
}
