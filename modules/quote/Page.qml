import QtQuick
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// The current quote, large, with New / Copy (its settings are in the
// settings window: QuoteSettings.qml). A Bible verse also gets Commentary:
// Matthew Henry's notes on it, fetched when asked, under the card.
Column {
  id: page
  property var mod: null
  spacing: SH.HubStyle.gap

  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  readonly property var q: mod ? mod.quote : null
  property bool showCommentary: false
  onQChanged: if (!mod || !mod.isVerse) showCommentary = false

  FontLoader { id: gothic; source: page.mod ? page.mod.fontUrl : "" }

  SH.HubCard {
    width: parent.width
    height: quoteCol.implicitHeight + SH.HubStyle.pad * 2 + Style.space(8)
    fg: page.fg; accent: page.accent
    Column {
      id: quoteCol
      x: SH.HubStyle.pad + Style.space(4); y: SH.HubStyle.pad + Style.space(4)
      width: parent.width - x * 2
      spacing: Style.space(10)
      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: page.q ? page.mod.upper : (page.mod ? page.mod.t("none") : "")
        color: page.fg
        wrapMode: Text.WordWrap
        font.family: page.mod ? page.mod.fontFor(gothic.name) : gothic.name
        font.pixelSize: Style.space(26)
      }
      Text {
        width: parent.width
        visible: text !== ""
        horizontalAlignment: Text.AlignHCenter
        text: page.mod ? page.mod.lower : ""
        color: Qt.darker(page.fg, 1.25)
        wrapMode: Text.WordWrap
        font.family: "Noto Serif"; font.italic: true
        font.pixelSize: Style.font.body + 1
      }
      Text {
        width: parent.width
        visible: !!(page.q && page.q.author)
        horizontalAlignment: Text.AlignHCenter
        text: page.q && page.q.author ? "— " + page.q.author : ""
        color: Qt.darker(page.fg, 1.7)
        font.family: "Noto Serif"; font.pixelSize: Style.font.caption
        font.letterSpacing: 1
      }
      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(8)
        SH.HubChip {
          icon: "󰑓"; label: page.mod ? page.mod.t("fresh") : ""
          on: true
          fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
          onClicked: page.mod.next()
        }
        SH.HubChip {
          id: copyChip
          property bool done: false
          icon: done ? "󰄬" : "󰆏"
          label: page.mod ? page.mod.t(done ? "copied" : "copy") : ""
          fg: page.fg; accent: page.accent; fontFamily: page.ff
          onClicked: { page.mod.copy(); done = true; copyReset.restart() }
          Timer { id: copyReset; interval: 1500; onTriggered: copyChip.done = false }
        }
        SH.HubChip {
          visible: !!(page.mod && page.mod.isVerse)
          icon: "\u{f05da}"; label: page.mod ? page.mod.t("commentary") : ""
          on: page.showCommentary
          fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
          onClicked: { page.showCommentary = !page.showCommentary; if (page.showCommentary) page.mod.loadCommentary() }
        }
      }
    }
  }

  SH.HubCard {
    visible: page.showCommentary && !!(page.mod && page.mod.isVerse)
    width: parent.width
    height: Math.min(Style.space(300), commCol.implicitHeight + SH.HubStyle.pad * 2)
    fg: page.fg; accent: page.accent
    clip: true
    Flickable {
      anchors.fill: parent
      anchors.margins: SH.HubStyle.pad
      contentHeight: commCol.implicitHeight
      boundsBehavior: Flickable.StopAtBounds
      Column {
        id: commCol
        width: parent.width
        spacing: Style.space(6)
        Text {
          text: page.mod ? page.mod.t("commentaryHint") : ""
          color: Qt.darker(page.fg, 1.6)
          font.family: page.ff; font.pixelSize: Style.font.caption - 1
        }
        Text {
          width: parent.width
          text: page.mod ? (page.mod.commentaryBusy ? "…" : page.mod.commentary) : ""
          color: Qt.darker(page.fg, 1.15)
          wrapMode: Text.WordWrap
          font.family: "Noto Serif"; font.pixelSize: Style.font.caption + 1
          lineHeight: 1.15
        }
      }
    }
  }
}
