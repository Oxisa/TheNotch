import QtQuick
import QtQuick.Controls
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// The Notes tool: search, archive, Markdown and "New" on top; the note being
// written in its own editor (a draft — the cards below don't rebuild under
// your cursor); then the other notes as cards with their title and lines,
// "[ ]" lines as tick boxes you can tick right on the card.
Column {
  id: page
  property var mod: null
  spacing: Style.space(10)
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }
  property string query: ""
  property bool archive: false
  readonly property color ink: "#2b2622"                          // text on the paper

  // the editor works on a copy
  property string editing: ""
  property string draftText: ""
  property string draftColor: "lemon"
  function edit(n) { editing = n.id; draftText = n.text; draftColor = n.color; ta.text = n.text; ta.forceActiveFocus() }
  function closeEditor(saveIt) {
    if (saveIt && editing) mod.update(editing, { text: ta.text, color: draftColor })
    editing = ""
  }
  function newNote() { closeEditor(true); var id = mod.add(); var n = mod.notes.filter(function(x) { return x.id === id })[0]; if (n) edit(n) }
  readonly property var shown: (mod ? mod.notes : []).filter(function(n) {
    return n.id !== page.editing && n.archived === page.archive && (!page.query || n.text.toLowerCase().indexOf(page.query.toLowerCase()) >= 0)
  })
  function titleOf(n) { return (n.text || "").split("\n")[0].trim() || page.t("Без названия", "Untitled") }

  Item {
    width: page.width; height: Style.space(30)
    SH.HubField { width: Style.space(240); icon: "\u{f0349}"; placeholderText: page.t("Найти в заметках…", "Search notes…"); fg: page.fg; accent: page.accent; fontFamily: page.ff; onTextChanged: page.query = text }
    Row {
      anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(6)
      SH.HubChip { icon: "\u{f0224}"; label: page.t("В Markdown", "Markdown"); on: page.mod && page.mod.exportMd; subtle: true; fg: page.fg; accent: page.accent; fontFamily: page.ff
                   onClicked: page.mod.persist({ markdown: !page.mod.exportMd }) }
      SH.HubChip { visible: page.mod && page.mod.exportMd; iconOnly: true; icon: "\u{f024b}"; label: page.t("Папка с .md", "The .md folder"); fg: page.fg; accent: page.accent; fontFamily: page.ff; onClicked: page.mod.openFolder() }
      SH.HubChip { icon: "\u{f003c}"; label: page.t("Архив", "Archive"); on: page.archive; subtle: true; fg: page.fg; accent: page.accent; fontFamily: page.ff; onClicked: { page.closeEditor(true); page.archive = !page.archive } }
      SH.HubChip { visible: !page.archive; icon: "\u{f0415}"; label: page.t("Новая", "New"); on: true; fg: page.fg; accent: page.accent; ink: Color.background; fontFamily: page.ff; onClicked: page.newNote() }
    }
  }

  // ------------------------------------------------------------- editor
  Rectangle {
    id: editor
    visible: page.editing !== ""
    width: page.width; height: Style.space(250)
    radius: Style.space(14)
    color: page.mod ? page.mod.colorOf(page.draftColor) : "white"
    ScrollView {
      x: Style.space(14); y: Style.space(12)
      width: parent.width - Style.space(28); height: parent.height - Style.space(58)
      TextArea {
        id: ta
        placeholderText: page.t("Первая строка — заголовок. «[ ] » — пункт с галочкой", "The first line is the title. “[ ] ” makes a tick box")
        wrapMode: TextArea.Wrap
        color: page.ink; placeholderTextColor: Qt.rgba(0, 0, 0, 0.4)
        font.family: page.ff; font.pixelSize: Style.font.body
        background: null
        Keys.onEscapePressed: page.closeEditor(true)
      }
    }
    Row {
      anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: Style.space(12)
      spacing: Style.space(6)
      Repeater {
        model: page.mod ? page.mod.colors : []
        delegate: Rectangle {
          required property var modelData
          width: Style.space(22); height: width; radius: width / 2
          color: modelData.c; border.width: page.draftColor === modelData.id ? 3 : 1; border.color: page.ink
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { page.draftColor = modelData.id; page.mod.update(page.editing, { color: modelData.id }) } }
        }
      }
    }
    Row {
      anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: Style.space(10)
      spacing: Style.space(6)
      component PaperBtn: Rectangle {
        property string label: ""
        signal clicked()
        width: pl.implicitWidth + Style.space(18); height: Style.space(28); radius: height / 2
        color: Qt.rgba(0, 0, 0, pm.containsMouse ? 0.18 : 0.08)
        Text { id: pl; anchors.centerIn: parent; text: parent.label; color: page.ink; font.family: page.ff; font.pixelSize: Style.font.caption; font.bold: true }
        MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
      }
      PaperBtn {
        readonly property bool arch: page.mod && page.editing ? (page.mod.notes.filter(function(n) { return n.id === page.editing })[0] || {}).archived === true : false
        label: arch ? page.t("Вернуть", "Restore") : page.t("В архив", "Archive")
        onClicked: { page.mod.update(page.editing, { text: ta.text, color: page.draftColor, archived: !arch }); page.editing = "" }
      }
      PaperBtn { label: page.t("Удалить", "Delete"); onClicked: { page.mod.remove(page.editing); page.editing = "" } }
      PaperBtn { label: page.t("Готово", "Done"); onClicked: page.closeEditor(true) }
    }
  }

  Text { visible: page.shown.length === 0 && page.editing === ""; text: page.archive ? page.t("Архив пуст", "The archive is empty") : page.t("Заметок нет — нажмите «Новая»", "No notes — press New"); color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption }

  // -------------------------------------------------------------- cards
  Flow {
    width: page.width
    spacing: Style.space(10)
    Repeater {
      model: page.shown
      delegate: Rectangle {
        id: card
        required property var modelData
        readonly property var body: (modelData.text || "").split("\n").slice(1).filter(function(l, i) { return i < 8 })
        width: (page.width - Style.space(20)) / 3
        height: Math.max(Style.space(110), col.implicitHeight + Style.space(26))
        radius: Style.space(14)
        color: page.mod.colorOf(modelData.color)
        MouseArea { anchors.fill: parent; cursorShape: Qt.IBeamCursor; onClicked: { page.closeEditor(true); page.edit(card.modelData) } }
        Column {
          id: col
          x: Style.space(14); y: Style.space(12)
          width: parent.width - Style.space(28)
          spacing: Style.space(4)
          Text { width: parent.width; elide: Text.ElideRight; text: page.titleOf(card.modelData); color: page.ink; font.family: page.ff; font.pixelSize: Style.font.body + 1; font.bold: true }
          Repeater {
            model: card.body
            delegate: Row {
              required property string modelData
              required property int index
              readonly property bool box: /^\s*\[( |x|X|✓)\]/.test(modelData)
              readonly property bool done: /^\s*\[(x|X|✓)\]/.test(modelData)
              spacing: Style.space(6)
              Rectangle {
                visible: parent.box
                anchors.verticalCenter: parent.verticalCenter
                width: Style.space(14); height: width; radius: Style.space(3)
                color: parent.done ? page.ink : "transparent"; border.width: 1.5; border.color: page.ink
                Text { anchors.centerIn: parent; visible: parent.parent.done; text: "\u{f012c}"; color: card.color; font.family: page.ff; font.pixelSize: Style.font.caption - 2 }
                MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: page.mod.toggleLine(card.modelData.id, index + 1) }
              }
              Text {
                width: col.width - (parent.box ? Style.space(20) : 0); wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                text: parent.box ? modelData.replace(/^\s*\[( |x|X|✓)\]\s*/, "") : modelData
                color: page.ink; opacity: parent.done ? 0.5 : 1; font.strikeout: parent.done
                font.family: page.ff; font.pixelSize: Style.font.caption + 1
              }
            }
          }
        }
      }
    }
  }
}
