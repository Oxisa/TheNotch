import QtQuick
import Quickshell
import qs.Commons
import "../../../osia.soundhub" as SH

// Clipboard's page: a search field and the recent copies; a click copies.
Column {
  id: page
  property var mod: null
  spacing: Style.space(8)
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property string ff: Style.font.family
  function t(a, b) { return mod ? mod.t(a, b) : b }
  property string filter: ""
  readonly property var rows: {
    var h = mod ? mod.history : [], out = [], f = filter.toLowerCase()
    for (var i = 0; i < h.length && out.length < 30; i++) {
      var e = h[i]
      if (f && (e.type !== "text" || String(e.text).toLowerCase().indexOf(f) < 0)) continue
      out.push({ i: i, e: e })
    }
    return out
  }

  Row {
    width: parent.width
    spacing: Style.space(6)
    SH.HubField {
      width: parent.width - more.width - clearBtn.width - parent.spacing * 2
      icon: "󰍉"
      placeholderText: page.t("Найти в истории…", "Search the history…")
      fg: page.fg; accent: page.accent; fontFamily: page.ff
      onTextEdited: page.filter = text
    }
    SH.HubChip {
      id: clearBtn
      property int confirm: 0
      icon: "\u{f01b4}"
      label: confirm ? page.t("Ещё раз — очистить", "Again to clear") : page.t("Очистить", "Clear")
      on: confirm > 0
      fg: page.fg; accent: page.accent; ink: Color.background; fontFamily: page.ff
      onClicked: { if (++confirm >= 2) { page.mod.clear(); confirm = 0 } else clearReset.restart() }
      Timer { id: clearReset; interval: 3000; onTriggered: clearBtn.confirm = 0 }
    }
    SH.HubChip {
      id: more
      iconOnly: true
      icon: "\u{f0a38}"
      label: page.t("Меню буфера Omarchy (там же очистка)", "Omarchy's clipboard menu (clearing is there)")
      fg: page.fg; accent: page.accent; fontFamily: page.ff
      onClicked: { page.mod.notch.expanded = false; Quickshell.execDetached(["omarchy-menu-clipboard"]) }
    }
  }
  Text {
    visible: page.rows.length === 0
    text: page.t("Ничего нет", "Nothing here")
    color: Qt.darker(page.fg, 1.6)
    font.family: page.ff; font.pixelSize: Style.font.caption
  }
  Repeater {
    model: page.rows
    delegate: Rectangle {
      id: row
      required property var modelData
      readonly property bool isImage: modelData.e.type === "image"
      width: page.width
      height: isImage ? Style.space(90) : Math.min(Style.space(66), txt.implicitHeight + Style.space(18))
      radius: SH.HubStyle.radiusSmall + Style.space(2)
      color: page.mod && page.mod.copiedIndex === modelData.i ? SH.HubStyle.tint(page.accent, 0.3)
             : SH.HubStyle.tint(page.fg, rm.containsMouse ? 0.10 : 0.05)
      clip: true
      Image {
        visible: row.isImage
        x: Style.space(8); y: Style.space(8)
        height: parent.height - Style.space(16); width: Math.min(parent.width - Style.space(16), height * 2.4)
        source: row.isImage ? "file://" + row.modelData.e.path : ""
        fillMode: Image.PreserveAspectFit
        horizontalAlignment: Image.AlignLeft
        asynchronous: true; sourceSize.height: 160
      }
      Text {
        id: txt
        visible: !row.isImage
        x: Style.space(12); y: Style.space(9)
        width: parent.width - Style.space(24)
        text: row.isImage ? "" : String(row.modelData.e.text).trim()
        maximumLineCount: 2; elide: Text.ElideRight; wrapMode: Text.WrapAnywhere
        color: page.fg
        font.family: page.ff; font.pixelSize: Style.font.caption + 1
      }
      Text {
        anchors.right: parent.right; anchors.rightMargin: Style.space(10)
        anchors.verticalCenter: parent.verticalCenter
        visible: page.mod && page.mod.copiedIndex === row.modelData.i
        text: "󰄬 " + page.t("скопировано", "copied")
        color: page.accent
        font.family: page.ff; font.pixelSize: Style.font.caption; font.bold: true
      }
      MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.mod.copy(row.modelData.i) }
    }
  }
}
