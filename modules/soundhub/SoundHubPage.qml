import QtQuick
import qs.Commons
import qs.Ui
import "../../../osia.soundhub" as SH

// SoundHub's tabs inside the notch (its settings are in the settings window): the same pages as the bar panel
// (loaded from the osia.soundhub folder, one copy of the code), under the
// same sliding segmented control. Pages are created on first visit and kept.
Column {
  id: root
  property var host: null
  spacing: Style.space(12)

  readonly property var tabs: [
    { icon: "󰝚", key: "tab.playing", file: "NowPlaying.qml" },
    { icon: "\u{f1542}", key: "tab.mixer", file: "MixerPage.qml" },
    { icon: "󰺢", key: "tab.eq", file: "EqPage.qml" },
    { icon: "󱅻", key: "tab.focus", file: "FocusPage.qml" }
  ]
  readonly property color fg: host ? host.fg : "white"

  Rectangle {
    id: strip
    width: parent.width
    height: SH.HubStyle.controlH + Style.space(8)
    radius: height / 2
    color: SH.HubStyle.tint(root.fg, SH.HubStyle.surface)
    readonly property real pad: Style.space(4)
    readonly property real tabW: (width - pad * 2) / root.tabs.length

    Rectangle {
      x: strip.pad + strip.tabW * (root.host ? root.host.tab : 0)
      y: strip.pad
      width: strip.tabW; height: strip.height - strip.pad * 2
      radius: height / 2
      color: root.host ? root.host.accent : "white"
      Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    }
    Repeater {
      model: root.tabs
      delegate: Item {
        id: tabItem
        required property var modelData
        required property int index
        readonly property bool current: root.host && root.host.tab === index
        x: strip.pad + strip.tabW * index; y: strip.pad
        width: strip.tabW; height: strip.height - strip.pad * 2
        Row {
          anchors.centerIn: parent
          spacing: Style.space(6)
          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: tabItem.modelData.icon
            color: tabItem.current ? Color.background : Qt.darker(root.fg, 1.25)
            font.family: root.host ? root.host.ff : ""; font.pixelSize: Style.font.body + 1
          }
          Text {
            visible: tabItem.current && strip.tabW > Style.space(110)
            anchors.verticalCenter: parent.verticalCenter
            text: root.host ? root.host.t(tabItem.modelData.key) : ""
            color: Color.background
            font.family: root.host ? root.host.ff : ""; font.pixelSize: Style.font.body; font.bold: true
          }
        }
        MouseArea {
          id: tabMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: if (root.host) root.host.tab = tabItem.index
        }
        PanelToolTip { visible: !tabItem.current && tabMouse.containsMouse; text: root.host ? root.host.t(tabItem.modelData.key) : "" }
      }
    }
  }

  Item {
    id: pageHost
    width: parent.width
    readonly property var cur: pages.count > (root.host ? root.host.tab : 0) ? pages.itemAt(root.host.tab) : null
    height: cur && cur.item ? cur.item.implicitHeight : 0
    Repeater {
      id: pages
      model: root.tabs
      delegate: Loader {
        id: pl
        required property var modelData
        required property int index
        property bool visited: false
        readonly property bool shown: root.host && root.host.tab === index
        onShownChanged: if (shown) visited = true
        Component.onCompleted: if (shown) visited = true
        width: pageHost.width
        visible: shown
        opacity: shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        active: visited
        source: Qt.resolvedUrl("../../../osia.soundhub/" + modelData.file)
        onLoaded: item.host = root.host
      }
    }
  }
}
