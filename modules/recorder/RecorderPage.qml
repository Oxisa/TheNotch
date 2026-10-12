import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// Recorder's page: the record button with what to record, then the
// recordings — play, transcribe, read/copy the text, open, delete.
Column {
  id: page
  property var mod: null
  spacing: SH.HubStyle.gap
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }

  property string playing: ""                 // id being played
  Process { id: player; onExited: page.playing = "" }
  function play(it) {
    if (playing === it.id) { player.running = false; playing = ""; return }
    player.running = false
    player.command = ["mpv", "--no-video", "--really-quiet", it.path]
    playing = it.id; player.running = true
  }
  property string open_: ""                   // id whose transcript is shown
  property string copied: ""

  SH.HubCard {
    width: parent.width
    height: top.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    Column {
      id: top
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      spacing: Style.space(10)
      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(16)
        Rectangle {
          width: Style.space(64); height: width; radius: width / 2
          color: page.mod && page.mod.recording ? Color.urgent : SH.HubStyle.tint(page.accent, recMouse.containsMouse ? 0.4 : 0.28)
          Rectangle {
            anchors.centerIn: parent
            width: page.mod && page.mod.recording ? Style.space(20) : Style.space(26); height: width
            radius: page.mod && page.mod.recording ? Style.space(4) : width / 2
            color: page.mod && page.mod.recording ? "white" : Color.urgent
            Behavior on radius { NumberAnimation { duration: 150 } }
          }
          MouseArea { id: recMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.mod.toggleRecording() }
        }
        Column {
          anchors.verticalCenter: parent.verticalCenter
          Text {
            text: page.mod && page.mod.recording ? page.mod.elapsed : page.t("Записать", "Record")
            color: page.fg
            font.family: page.ff; font.pixelSize: Style.space(26); font.bold: true
          }
          Text {
            text: page.mod && page.mod.recording ? page.t("Нажмите ещё раз, чтобы остановить", "Click again to stop")
                                                 : page.t("Сохраняется в ", "Saved to ") + (page.mod ? String(page.mod.st.root || "").replace(Quickshell.env("HOME"), "~") : "")
            color: Qt.darker(page.fg, 1.5)
            font.family: page.ff; font.pixelSize: Style.font.caption - 1
          }
        }
      }
      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(6)
        enabled: page.mod && !page.mod.recording
        opacity: enabled ? 1 : 0.5
        Repeater {
          model: [{ sys: false, icon: "\u{f036c}", label: page.t("Микрофон", "Microphone") },
                  { sys: true, icon: "\u{f02cb}", label: page.t("Микрофон + звук системы", "Mic + system sound") }]
          delegate: SH.HubChip {
            required property var modelData
            icon: modelData.icon; label: modelData.label
            on: page.mod && page.mod.withSystem === modelData.sys
            subtle: true
            h: Style.space(26)
            fg: page.fg; accent: page.accent; fontFamily: page.ff
            onClicked: page.mod.persist({ system: modelData.sys })
          }
        }
      }
      Text {
        visible: page.mod && page.mod.withSystem && !page.mod.recording
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: page.t("Для созвонов: наденьте наушники, иначе собеседник запишется дважды.", "For calls: wear headphones, or the other side is recorded twice.")
        color: Qt.darker(page.fg, 1.6)
        font.family: page.ff; font.pixelSize: Style.font.caption - 1
      }
    }
  }

  Text {
    visible: page.mod && page.mod.items.length === 0
    text: page.t("Записей пока нет", "No recordings yet")
    color: Qt.darker(page.fg, 1.6)
    font.family: page.ff; font.pixelSize: Style.font.caption
  }

  Repeater {
    model: page.mod ? page.mod.items.slice(0, 20) : []
    delegate: SH.HubCard {
      id: rc
      required property var modelData
      readonly property bool working: page.mod && page.mod.st.jobs && !!page.mod.st.jobs[modelData.id]
      readonly property bool shown: page.open_ === modelData.id
      width: page.width
      height: rcCol.implicitHeight + Style.space(20)
      fg: page.fg; accent: page.accent
      Column {
        id: rcCol
        x: Style.space(12); y: Style.space(10)
        width: parent.width - Style.space(24)
        spacing: Style.space(6)
        Item {
          width: parent.width; height: Style.space(30)
          Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - actions.width - Style.space(8)
            Text { width: parent.width; elide: Text.ElideRight; text: rc.modelData.title; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption + 1; font.bold: true }
            Text {
              text: page.mod.fmt(rc.modelData.duration || 0) + (rc.modelData.system ? page.t("  ·  с системным звуком", "  ·  with system sound") : "")
                    + (rc.working ? page.t("  ·  расшифровка…", "  ·  transcribing…") : rc.modelData.transcript ? page.t("  ·  есть текст", "  ·  has text") : "")
              color: rc.working ? page.accent : Qt.darker(page.fg, 1.5)
              font.family: page.ff; font.pixelSize: Style.font.caption - 2
            }
          }
          Row {
            id: actions
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(4)
            Repeater {
              model: [
                { id: "play", icon: page.playing === rc.modelData.id ? "\u{f04db}" : "\u{f040a}", tip: page.t("Слушать", "Play") },
                { id: "text", icon: "\u{f0a38}", tip: rc.modelData.transcript ? page.t("Текст", "Text") : page.t("Расшифровать", "Transcribe"), on: rc.shown },
                { id: "dir", icon: "\u{f0256}", tip: page.t("Открыть папку", "Open folder") },
                { id: "del", icon: "\u{f01b4}", tip: page.t("Удалить", "Delete") }]
              delegate: SH.HubChip {
                required property var modelData
                iconOnly: true
                icon: modelData.icon; label: modelData.tip
                on: !!modelData.on
                h: Style.space(26)
                fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
                property int confirm: 0
                onClicked: {
                  var it = rc.modelData
                  if (modelData.id === "play") page.play(it)
                  else if (modelData.id === "text") { page.open_ = rc.shown ? "" : it.id; if (!it.transcript && !rc.working) page.mod.transcribe(it.id) }
                  else if (modelData.id === "dir") Quickshell.execDetached(["xdg-open", it.path.replace(/\/audio\.wav$/, "")])
                  else if (modelData.id === "del") { if (++confirm >= 2) page.mod.cmd(["delete", it.id]); else delTimer.restart() }
                }
                Timer { id: delTimer; interval: 3000; onTriggered: parent.confirm = 0 }
              }
            }
          }
        }
        Text {
          visible: rc.shown
          width: parent.width
          wrapMode: Text.WordWrap
          text: rc.modelData.transcript ? rc.modelData.transcript.trim()
                : rc.working ? page.t("Расшифровываю на этом компьютере…", "Transcribing on this machine…")
                : page.mod && !page.mod.st.models.length ? page.t("Нет модели: скачайте её в настройках «Диктофона»", "No model: download one in Recorder's settings")
                : ""
          color: Qt.darker(page.fg, 1.1)
          font.family: page.ff; font.pixelSize: Style.font.caption + 1
          lineHeight: 1.2
        }
        Row {
          visible: rc.shown && !!rc.modelData.transcript
          spacing: Style.space(6)
          SH.HubChip {
            icon: page.copied === rc.modelData.id ? "󰄬" : "󰆏"
            label: page.copied === rc.modelData.id ? page.t("Скопировано", "Copied") : page.t("Копировать", "Copy")
            h: Style.space(24)
            fg: page.fg; accent: page.accent; fontFamily: page.ff
            onClicked: { Quickshell.execDetached(["wl-copy", rc.modelData.transcript.trim()]); page.copied = rc.modelData.id }
          }
          SH.HubChip {
            icon: "\u{f0450}"; label: page.t("Заново", "Again")
            h: Style.space(24)
            fg: page.fg; accent: page.accent; fontFamily: page.ff
            onClicked: page.mod.transcribe(rc.modelData.id)
          }
        }
      }
    }
  }
}
