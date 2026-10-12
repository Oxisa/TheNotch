import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// The task manager under the System tab's rings, btop-style: a bar per CPU
// core, then the processes grouped by app (sort by CPU or memory, search),
// and "End" for your own — a second click if it doesn't go. Numbers from
// bin/procs while this is on screen; btop itself is a button away.
Rectangle {
  id: tm
  property var mod: null
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }
  radius: SH.HubStyle.radius + Style.space(2)
  color: SH.HubStyle.tint(fg, 0.05)
  border.width: 1; border.color: SH.HubStyle.tint(fg, 0.06)
  height: col.implicitHeight + Style.space(24)

  property var d: ({ cores: [], procs: [], total: 0 })
  property string sortBy: "cpu"
  property string filter: ""
  Process {
    running: tm.visible
    command: [decodeURIComponent(Qt.resolvedUrl("bin/procs").toString().replace(/^file:\/\//, ""))]
    stdout: SplitParser { onRead: function(line) { try { tm.d = JSON.parse(line) } catch (e) {} } }
  }
  readonly property var shown: (d.procs || []).filter(function(p) { return !filter || appName(p).toLowerCase().indexOf(filter.toLowerCase()) >= 0 })
                                .sort(function(a, b) { return sortBy === "mem" ? b.mem - a.mem : (b.cpu - a.cpu) || (b.mem - a.mem) })
                                .slice(0, 40)
  function entry(p) { return DesktopEntries.heuristicLookup(String(p.name).replace(/-bin$/, "")) }
  function appName(p) { var e = entry(p); return e && e.name ? e.name : p.name }
  function icon(p) { var e = entry(p); return e && e.icon ? Quickshell.iconPath(e.icon, true) : "" }
  function mem(b) { return b >= 1073741824 ? (b / 1073741824).toFixed(1) + page_t(" ГБ", " GB") : Math.round(b / 1048576) + page_t(" МБ", " MB") }
  function page_t(a, b) { return t(a, b) }
  // end the app: SIGTERM first; asked again within 5 s → SIGKILL
  property var ending: ({})
  function end(p) {
    var hard = ending[p.name] && Date.now() - ending[p.name] < 5000
    Quickshell.execDetached(["kill", hard ? "-KILL" : "-TERM"].concat(p.pids.map(String)))
    var e = Object.assign({}, ending); e[p.name] = hard ? 0 : Date.now(); ending = e
  }

  Column {
    id: col
    x: Style.space(14); y: Style.space(12)
    width: parent.width - Style.space(28)
    spacing: Style.space(10)
    Item {
      width: parent.width; height: Style.space(28)
      Text { anchors.verticalCenter: parent.verticalCenter; text: "\u{f0ee0}  " + tm.t("Процессы", "Processes") + (tm.d.total ? "  ·  " + tm.d.total : ""); color: tm.fg; font.family: tm.ff; font.pixelSize: Style.font.body; font.bold: true }
      Row {
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(4)
        SH.HubField {
          width: Style.space(150); icon: "\u{f0349}"
          placeholderText: tm.t("Найти…", "Find…")
          fg: tm.fg; accent: tm.accent; fontFamily: tm.ff
          onTextChanged: tm.filter = text
        }
        SH.HubChip { label: tm.t("ЦП", "CPU"); on: tm.sortBy === "cpu"; subtle: true; h: Style.space(26); fg: tm.fg; accent: tm.accent; fontFamily: tm.ff; onClicked: tm.sortBy = "cpu" }
        SH.HubChip { label: tm.t("Память", "Memory"); on: tm.sortBy === "mem"; subtle: true; h: Style.space(26); fg: tm.fg; accent: tm.accent; fontFamily: tm.ff; onClicked: tm.sortBy = "mem" }
        SH.HubChip { icon: "\u{f018d}"; label: "btop"; h: Style.space(26); fg: tm.fg; accent: tm.accent; fontFamily: tm.ff; onClicked: Quickshell.execDetached(["omarchy-launch-tui", "btop"]) }
      }
    }
    // a bar per core
    Row {
      width: parent.width
      spacing: Style.space(3)
      Repeater {
        model: tm.d.cores || []
        delegate: Item {
          required property real modelData
          required property int index
          width: (col.width - Style.space(3) * ((tm.d.cores || []).length - 1)) / Math.max(1, (tm.d.cores || []).length)
          height: Style.space(46)
          Rectangle { anchors.fill: parent; anchors.bottomMargin: Style.space(12); radius: Style.space(3); color: SH.HubStyle.tint(tm.fg, 0.07) }
          Rectangle {
            anchors.bottom: parent.bottom; anchors.bottomMargin: Style.space(12)
            width: parent.width; radius: Style.space(3)
            height: (parent.height - Style.space(12)) * Math.min(1, modelData / 100)
            color: modelData > 85 ? Color.urgent : tm.accent
            Behavior on height { NumberAnimation { duration: 400 } }
          }
          Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; text: index; color: Qt.darker(tm.fg, 1.8); font.family: tm.ff; font.pixelSize: Style.font.caption - 3 }
        }
      }
    }
    // the list
    Item {
      width: parent.width; height: Style.space(20)
      Text { x: Style.space(30); text: tm.t("Приложение", "App"); color: Qt.darker(tm.fg, 1.5); font.family: tm.ff; font.pixelSize: Style.font.caption - 1 }
      Text { x: parent.width - Style.space(260); width: Style.space(70); horizontalAlignment: Text.AlignRight; text: tm.t("ЦП", "CPU"); color: Qt.darker(tm.fg, 1.5); font.family: tm.ff; font.pixelSize: Style.font.caption - 1 }
      Text { x: parent.width - Style.space(180); width: Style.space(80); horizontalAlignment: Text.AlignRight; text: tm.t("Память", "Memory"); color: Qt.darker(tm.fg, 1.5); font.family: tm.ff; font.pixelSize: Style.font.caption - 1 }
    }
    Flickable {
      width: parent.width
      height: Math.min(Style.space(330), list.implicitHeight)
      contentHeight: list.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      Column {
        id: list
        width: parent.width
        Repeater {
          model: tm.shown
          delegate: Rectangle {
            id: row
            required property var modelData
            readonly property bool asking: !!(tm.ending[modelData.name] && Date.now() - tm.ending[modelData.name] < 5000)
            width: list.width; height: Style.space(32)
            radius: Style.space(8)
            color: rm.containsMouse ? SH.HubStyle.tint(tm.fg, 0.07) : "transparent"
            MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true }
            IconImage { x: Style.space(6); anchors.verticalCenter: parent.verticalCenter; width: Style.space(18); height: width; source: tm.icon(row.modelData) }
            Text {
              x: Style.space(30); anchors.verticalCenter: parent.verticalCenter
              width: parent.width - Style.space(300); elide: Text.ElideRight
              text: tm.appName(row.modelData) + (row.modelData.count > 1 ? "  (" + row.modelData.count + ")" : "") + (row.modelData.mine ? "" : "  · " + row.modelData.user)
              color: row.modelData.mine ? tm.fg : Qt.darker(tm.fg, 1.5); font.family: tm.ff; font.pixelSize: Style.font.caption + 1
            }
            Rectangle {                                   // a CPU bar behind the number
              x: parent.width - Style.space(260); anchors.verticalCenter: parent.verticalCenter
              width: Style.space(70); height: Style.space(18); radius: Style.space(4)
              color: "transparent"
              Rectangle { anchors.right: parent.right; width: parent.width * Math.min(1, row.modelData.cpu / 50); height: parent.height; radius: parent.radius; color: SH.HubStyle.tint(tm.accent, 0.3) }
              Text { anchors.right: parent.right; anchors.rightMargin: Style.space(4); anchors.verticalCenter: parent.verticalCenter; text: row.modelData.cpu.toFixed(1) + "%"; color: tm.fg; font.family: tm.ff; font.pixelSize: Style.font.caption }
            }
            Text { x: parent.width - Style.space(180); width: Style.space(80); anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignRight; text: tm.mem(row.modelData.mem); color: tm.fg; font.family: tm.ff; font.pixelSize: Style.font.caption }
            SH.HubChip {
              visible: row.modelData.mine && (rm.containsMouse || row.asking || hovered)
              property bool hovered: false
              anchors.right: parent.right; anchors.rightMargin: Style.space(4); anchors.verticalCenter: parent.verticalCenter
              icon: "\u{f0156}"; label: row.asking ? tm.t("Принудительно", "Force") : tm.t("Завершить", "End")
              on: row.asking; h: Style.space(24)
              fg: tm.fg; accent: row.asking ? Color.urgent : tm.accent; ink: Color.background; fontFamily: tm.ff
              onClicked: tm.end(row.modelData)
            }
          }
        }
      }
    }
  }
}
