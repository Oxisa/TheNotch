import QtQuick
import qs.Commons
import "../../fonts"
import "../../vendor/soundhub" as SH

// Settings → Workspaces: a name and a tiling mode per workspace, and the
// overview's key.
Column {
  id: page
  property var mod: null
  spacing: SH.HubStyle.gap
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }
  // the usual ten, plus any other in use
  readonly property var ids: {
    var out = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    if (mod) mod.workspaces.forEach(function(w) { if (out.indexOf(w.id) < 0) out.push(w.id) })
    return out.sort(function(a, b) { return a - b })
  }
  readonly property var modes: [
    { value: "", label: page.t("Как везде", "Default") },
    { value: "dwindle", label: page.t("Спираль (dwindle)", "Dwindle") },
    { value: "master", label: page.t("Главное окно (master)", "Master") },
    { value: "scrolling", label: page.t("Лента (scrolling)", "Scrolling") }
  ]

  SH.HubCard {
    width: page.width
    height: c0.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    Column {
      id: c0
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      spacing: Style.space(4)
      SH.HubRow {
        width: parent.width
        title: page.t("Обзор по Super + `", "Overview on Super + `")
        hint: page.t("Все столы монитора и окна вживую; перетащите окно на другой стол", "The monitor's workspaces and windows, live; drag a window to another workspace")
        fg: page.fg; fontFamily: page.ff
        SH.HubSwitch { checked: !!(page.mod && page.mod.hotkey); fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.mod.setHotkey(!page.mod.hotkey) }
      }
    }
  }

  SH.HubCard {
    width: page.width
    height: c1.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    Column {
      id: c1
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      spacing: Style.space(4)
      SH.HubCaption { text: page.t("Столы", "Workspaces"); icon: "\u{f0570}"; fg: page.fg; fontFamily: page.ff }
      Text { width: parent.width; wrapMode: Text.Wrap; text: page.t("Имя видно в обзоре и в чёлке. Раскладка — как стол расставляет окна", "The name shows in the overview and the notch. The mode is how the workspace tiles its windows"); color: Qt.darker(page.fg, 1.5); font.family: page.ff; font.pixelSize: Style.font.caption - 1 }
      Repeater {
        model: page.ids
        delegate: Item {
          required property int modelData
          readonly property bool used: page.mod ? page.mod.workspaces.some(function(w) { return w.id === modelData }) : false
          width: c1.width; height: Style.space(40)
          Text { anchors.verticalCenter: parent.verticalCenter; width: Style.space(28); text: String(modelData); color: used ? page.accent : page.fg; font.family: page.ff; font.pixelSize: Style.font.body; font.bold: true }
          SH.HubField {
            x: Style.space(32); anchors.verticalCenter: parent.verticalCenter
            width: parent.width - Style.space(32) - modeSel.width - Style.space(10)
            text: page.mod ? (page.mod.names[String(modelData)] || "") : ""
            placeholderText: page.t("Без имени", "No name")
            fg: page.fg; accent: page.accent; fontFamily: page.ff
            onEditingFinished: page.mod.setName(modelData, text.trim())
          }
          SH.HubSelect {
            id: modeSel
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            width: Style.space(200); showLabel: false
            options: page.modes
            value: page.mod ? page.mod.layoutOf(modelData) : ""
            foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
            onChanged: function(v) { page.mod.setLayout(modelData, v) }
          }
        }
      }
    }
  }
}
