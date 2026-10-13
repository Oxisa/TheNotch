import QtQuick
import Quickshell
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// Sound → Ambient: tracks that loop in the background, like Focus but with
// your own music — files, or a YouTube / YouTube Music link. Each has its
// own volume; one switch plays or pauses them all.
Column {
  id: page
  property var host: null
  spacing: Style.space(10)
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  readonly property bool ru: host ? host.ru : true
  function t(a, b) { return ru ? a : b }
  readonly property var amb: host ? host.amb : null

  Item {
    width: page.width; height: Style.space(40)
    SH.HubChip {
      anchors.verticalCenter: parent.verticalCenter
      icon: page.amb && page.amb.playing ? "\u{f03e4}" : "\u{f040a}"
      label: page.amb && page.amb.playing ? page.t("Пауза", "Pause") : page.t("Играть", "Play")
      on: !!(page.amb && page.amb.playing)
      fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
      onClicked: page.amb.toggle()
    }
    Row {
      anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(8)
      Text { anchors.verticalCenter: parent.verticalCenter; text: "\u{f057e}"; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.body }
      SH.HubSlider { anchors.verticalCenter: parent.verticalCenter; width: Style.space(160); value: page.amb ? page.amb.master : 1; onReleased: function(v) { page.amb.setMaster(v) } }
    }
  }
  Text { visible: !!page.amb && page.amb.items.length === 0; width: page.width; wrapMode: Text.Wrap; text: page.t("Пусто. Добавьте файлы или ссылку — они будут играть по кругу на фоне, пока вы работаете.", "Empty. Add files or a link — they loop in the background while you work."); color: Qt.darker(page.fg, 1.5); font.family: page.ff; font.pixelSize: Style.font.caption }

  Repeater {
    model: page.amb ? page.amb.items : []
    delegate: Rectangle {
      id: row
      required property var modelData
      required property int index
      readonly property var state: page.amb ? page.amb.stateOf(modelData.id) : ({})
      width: page.width; height: Style.space(52)
      radius: Style.space(12)
      color: SH.HubStyle.tint(page.fg, 0.05)
      SH.HubSwitch { x: Style.space(10); anchors.verticalCenter: parent.verticalCenter; checked: row.modelData.on !== false; fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.amb.update(row.modelData.id, { on: !checked }) }
      Column {
        x: Style.space(64); anchors.verticalCenter: parent.verticalCenter
        width: parent.width - Style.space(64) - vol.width - del.width - Style.space(30)
        Text { width: parent.width; elide: Text.ElideRight; text: (/^https?:/.test(row.modelData.src) ? "\u{f05c3}  " : "\u{f0387}  ") + row.modelData.name; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption + 1; font.bold: true }
        Text { width: parent.width; elide: Text.ElideMiddle; text: row.state.error ? page.t("Не играет: ", "Not playing: ") + row.state.error : row.modelData.src; color: row.state.error ? Color.urgent : Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption - 2 }
      }
      SH.HubSlider { id: vol; anchors.right: del.left; anchors.rightMargin: Style.space(10); anchors.verticalCenter: parent.verticalCenter; width: Style.space(130); value: row.modelData.volume !== undefined ? row.modelData.volume : 0.6; onReleased: function(v) { page.amb.update(row.modelData.id, { volume: v }) } }
      SH.HubChip { id: del; anchors.right: parent.right; anchors.rightMargin: Style.space(8); anchors.verticalCenter: parent.verticalCenter; iconOnly: true; icon: "\u{f0156}"; label: page.t("Убрать", "Remove"); fg: page.fg; accent: page.accent; fontFamily: page.ff; onClicked: page.amb.remove(row.modelData.id) }
    }
  }

  Row {
    width: page.width
    spacing: Style.space(6)
    SH.HubChip { id: files; icon: "\u{f0415}"; label: page.t("Файлы…", "Files…"); fg: page.fg; accent: page.accent; fontFamily: page.ff; onClicked: page.amb.pickFiles() }
    SH.HubField {
      id: link
      width: parent.width - files.width - addLink.width - Style.space(12)
      icon: "\u{f0337}"
      placeholderText: page.t("Ссылка на YouTube / YouTube Music или на аудиофайл", "A YouTube / YouTube Music link or an audio file's address")
      fg: page.fg; accent: page.accent; fontFamily: page.ff
      onAccepted: addLink.clicked()
    }
    SH.HubChip { id: addLink; label: page.t("Добавить", "Add"); on: true; fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
                 onClicked: { if (/^https?:\/\//.test(link.text.trim())) { page.amb.addLink(link.text.trim()); link.text = "" } } }
  }
  Text {
    width: page.width; wrapMode: Text.Wrap
    text: page.t("Spotify не отдаёт звук сторонним плеерам (защита DRM), поэтому его ссылки здесь не заиграют.", "Spotify doesn't give its audio to other players (DRM), so its links won't play here.")
    color: Qt.darker(page.fg, 1.8); font.family: page.ff; font.pixelSize: Style.font.caption - 2
  }
}
