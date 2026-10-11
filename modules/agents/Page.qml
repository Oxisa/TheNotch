import QtQuick
import QtQuick.Controls
import qs.Commons
import "../../../osia.soundhub" as SH

// Agents dashboard, one block: a nested ring per agent with limits, the
// agent chips and the ask field (Enter = quick answer here, Shift+Enter / ↗ =
// the full agent in a terminal). The answer shows under it when there is one.
Column {
  id: page
  property var mod: null
  spacing: SH.HubStyle.gap

  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property color urgent: Color.urgent
  readonly property string ff: Style.font.family
  function t(a, b) { return mod ? mod.t(a, b) : b }

  // ------------------------------------------------------------- ask
  SH.HubCard {
    width: parent.width
    height: askCol.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    Column {
      id: askCol
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      spacing: Style.space(12)
      // one nested ring per agent with limits (outer: session, inner: week)
      Row {
        visible: page.mod && page.mod.agents.length > 0
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(36)
        Repeater {
          model: page.mod ? page.mod.agents : []
          delegate: RingPair {
            required property var modelData
            agentData: modelData
            ru: page.mod ? page.mod.ru : true
            size: Style.space(76)
          }
        }
      }
      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(6)
        Repeater {
          model: page.mod ? page.mod.known.filter(function(a) { return page.mod.installed.indexOf(a.id) >= 0 }) : []
          delegate: SH.HubChip {
            required property var modelData
            icon: modelData.glyph
            label: modelData.name
            on: page.mod && page.mod.agent === modelData.id
            h: Style.space(26)
            fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
            onClicked: page.mod.choose(modelData.id)
          }
        }
        Text {
          visible: page.mod && page.mod.installed.length === 0
          text: page.t("Агенты не найдены (claude, codex, gemini, opencode)", "No agents found (claude, codex, gemini, opencode)")
          color: Qt.darker(page.fg, 1.6)
          font.family: page.ff; font.pixelSize: Style.font.caption
        }
      }
      Row {
        width: parent.width
        spacing: Style.space(6)
        SH.HubField {
          id: field
          width: parent.width - send.width - term.width - parent.spacing * 2
          icon: "\u{f0674}"
          placeholderText: page.t("Спросить агента…", "Ask the agent…")
          fg: page.fg; accent: page.accent; fontFamily: page.ff
          onAccepted: { page.mod.ask(text); }
          onShiftAccepted: { page.mod.openInTerminal(text); text = "" }
        }
        SH.HubChip {
          id: send
          iconOnly: true
          icon: page.mod && page.mod.asking ? "\u{f04db}" : "\u{f048a}"
          label: page.mod && page.mod.asking ? page.t("Стоп", "Stop") : page.t("Ответ здесь (Enter)", "Answer here (Enter)")
          on: true
          danger: page.mod && page.mod.asking
          fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
          onClicked: page.mod.asking ? page.mod.cancelAsk() : page.mod.ask(field.text)
        }
        SH.HubChip {
          id: term
          iconOnly: true
          icon: "\u{f03cc}"
          label: page.t("Открыть агента в терминале (Shift+Enter)", "Open the agent in a terminal (Shift+Enter)")
          fg: page.fg; accent: page.accent; fontFamily: page.ff
          onClicked: { page.mod.openInTerminal(field.text); field.text = "" }
        }
      }
    }
  }

  // ---------------------------------------------------------- answer
  SH.HubCard {
    visible: page.mod && (page.mod.asking || page.mod.answer !== "" || page.mod.askError !== "")
    width: parent.width
    height: ansCol.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    Column {
      id: ansCol
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      spacing: Style.space(8)
      Text {
        width: parent.width
        text: (page.mod ? page.mod.askedAgent : "") + "  ·  " + (page.mod ? page.mod.question : "")
        color: Qt.darker(page.fg, 1.6)
        font.family: page.ff; font.pixelSize: Style.font.caption - 1
        elide: Text.ElideRight
      }
      Row {
        visible: page.mod && page.mod.asking
        spacing: Style.space(8)
        Text {
          text: "\u{f051f}"
          color: page.accent
          font.family: page.ff; font.pixelSize: Style.font.body
          RotationAnimator on rotation { running: page.mod && page.mod.asking; from: 0; to: 360; duration: 1600; loops: Animation.Infinite }
        }
        Text {
          text: page.t("Агент думает…", "The agent is thinking…")
          color: Qt.darker(page.fg, 1.3)
          font.family: page.ff; font.pixelSize: Style.font.caption
        }
      }
      Text {
        visible: page.mod && page.mod.askError !== ""
        width: parent.width
        wrapMode: Text.Wrap
        text: page.mod ? page.mod.askError : ""
        color: page.urgent
        font.family: page.ff; font.pixelSize: Style.font.caption
      }
      Flickable {
        visible: page.mod && page.mod.answer !== ""
        width: parent.width
        height: Math.min(ans.implicitHeight, Style.space(300))
        contentHeight: ans.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        TextEdit {
          id: ans
          width: parent.width - Style.space(10)
          readOnly: true
          selectByMouse: true
          wrapMode: TextEdit.Wrap
          textFormat: TextEdit.MarkdownText
          text: page.mod ? page.mod.answer : ""
          color: page.fg
          selectionColor: SH.HubStyle.tint(page.accent, 0.45)
          font.family: page.ff; font.pixelSize: Style.font.caption + 1
        }
      }
      Row {
        visible: page.mod && page.mod.answer !== ""
        spacing: Style.space(6)
        SH.HubChip {
          id: copyBtn
          property bool done: false
          icon: done ? "󰄬" : "\u{f018f}"; label: page.t(done ? "Скопировано" : "Копировать", done ? "Copied" : "Copy")
          h: Style.space(26)
          fg: page.fg; accent: page.accent; fontFamily: page.ff
          onClicked: { page.mod.copy(page.mod.answer); done = true; copyReset.restart() }
          Timer { id: copyReset; interval: 1500; onTriggered: copyBtn.done = false }
        }
        SH.HubChip {
          icon: "\u{f03cc}"; label: page.t("Продолжить в терминале", "Continue in a terminal")
          h: Style.space(26)
          fg: page.fg; accent: page.accent; fontFamily: page.ff
          onClicked: page.mod.openInTerminal(page.mod.question)
        }
        SH.HubChip {
          iconOnly: true; icon: "󰅖"; label: page.t("Убрать ответ", "Clear the answer")
          h: Style.space(26)
          fg: page.fg; accent: page.accent; fontFamily: page.ff
          onClicked: { page.mod.answer = ""; page.mod.askError = "" }
        }
      }
    }
  }
}
