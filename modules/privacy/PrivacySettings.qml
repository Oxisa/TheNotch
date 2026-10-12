import QtQuick
import Quickshell.Widgets
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// Settings → Privacy: who uses the mic and the camera now, the log, and
// the two switches (dots in the notch, a message when an app starts).
Column {
  id: page
  property var mod: null
  spacing: SH.HubStyle.gap
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }
  function ago(ms) {
    var m = Math.round((Date.now() - ms) / 60000)
    if (m < 1) return t("только что", "just now")
    if (m < 60) return m + t(" мин назад", " min ago")
    var d = new Date(ms)
    return Qt.formatDateTime(d, new Date().toDateString() === d.toDateString() ? "HH:mm" : "d MMM, HH:mm")
  }
  function span(ms) {
    var m = Math.round(ms / 60000)
    if (m < 1) return t("меньше минуты", "under a minute")
    if (m < 60) return m + t(" мин", " min")
    return Math.floor(m / 60) + t(" ч ", " h ") + (m % 60) + t(" мин", " min")
  }
  function times(n) {
    if (!ru) return n + (n === 1 ? " time" : " times")
    var d = n % 10, h = n % 100
    return n + (d >= 2 && d <= 4 && (h < 12 || h > 14) ? " раза" : " раз")
  }
  readonly property bool ru: mod ? mod.ru : true

  // now
  Row {
    width: page.width
    spacing: SH.HubStyle.gap
    Repeater {
      model: ["mic", "cam"]
      delegate: SH.HubCard {
        id: nowCard
        required property string modelData
        readonly property var apps: page.mod ? (modelData === "mic" ? page.mod.mic : page.mod.cam) : []
        readonly property color dot: modelData === "mic" ? page.mod.micColor : page.mod.camColor
        width: (page.width - SH.HubStyle.gap) / 2
        height: nc.implicitHeight + SH.HubStyle.pad * 2
        fg: page.fg; accent: page.accent
        Column {
          id: nc
          x: SH.HubStyle.pad; y: SH.HubStyle.pad
          width: parent.width - SH.HubStyle.pad * 2
          spacing: Style.space(8)
          Row {
            spacing: Style.space(8)
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Style.space(10); height: width; radius: width / 2; color: nowCard.apps.length ? nowCard.dot : SH.HubStyle.tint(page.fg, 0.2) }
            Text { text: nowCard.modelData === "mic" ? page.t("Микрофон", "Microphone") : page.t("Камера", "Camera"); color: page.fg; font.family: page.ff; font.pixelSize: Style.font.body; font.bold: true }
          }
          Text { visible: !nowCard.apps.length; text: page.t("Сейчас никто не использует", "Not in use"); color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption }
          Repeater {
            model: nowCard.apps
            delegate: Row {
              required property var modelData
              spacing: Style.space(8)
              IconImage { width: Style.space(22); height: width; source: page.mod.iconOf(modelData); visible: source != "" }
              Text { anchors.verticalCenter: parent.verticalCenter; text: page.mod.nameOf(modelData); color: page.fg; font.family: page.ff; font.pixelSize: Style.font.body }
            }
          }
        }
      }
    }
  }

  SH.HubCard {
    width: page.width
    height: sw.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    Column {
      id: sw
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      spacing: Style.space(4)
      SH.HubRow {
        width: parent.width
        title: page.t("Точки в чёлке", "Dots in the notch"); hint: page.t("Оранжевая — микрофон, зелёная — камера; наведите, чтобы увидеть кто", "Orange — microphone, green — camera; hover to see who")
        fg: page.fg; fontFamily: page.ff
        SH.HubSwitch { checked: !!(page.mod && page.mod.showDots); fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.mod.persist({ dots: !page.mod.showDots }) }
      }
      SH.HubRow {
        width: parent.width
        title: page.t("Сообщать о включении", "Tell when an app starts"); hint: page.t("Короткое сообщение в чёлке, когда приложение включает микрофон или камеру", "A short message in the notch when an app turns on the mic or camera")
        fg: page.fg; fontFamily: page.ff
        SH.HubSwitch { checked: !!(page.mod && page.mod.announce); fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.mod.persist({ announce: !page.mod.announce }) }
      }
    }
  }

  // the log
  SH.HubCard {
    width: page.width
    height: lg.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    Column {
      id: lg
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      spacing: Style.space(6)
      Item {
        width: parent.width; height: Style.space(28)
        SH.HubCaption { anchors.verticalCenter: parent.verticalCenter; text: page.t("Журнал", "Log"); icon: "\u{f02da}"; fg: page.fg; fontFamily: page.ff }
        SH.HubChip { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; visible: page.mod && page.mod.log.length > 0; icon: "\u{f0a7a}"; label: page.t("Очистить", "Clear"); subtle: true; h: Style.space(26); fg: page.fg; accent: page.accent; fontFamily: page.ff; onClicked: page.mod.clearLog() }
      }
      Text { visible: !page.mod || !page.mod.log.length; text: page.t("Пока пусто", "Nothing yet"); color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption }
      Repeater {
        model: page.mod ? page.mod.summary : []
        delegate: Item {
          required property var modelData
          width: lg.width; height: Style.space(28)
          Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Style.space(8); height: width; radius: width / 2; color: modelData.kind === "mic" ? page.mod.micColor : page.mod.camColor }
          IconImage { x: Style.space(16); anchors.verticalCenter: parent.verticalCenter; width: Style.space(20); height: width; source: page.mod.iconOf(modelData) }
          Text { x: Style.space(44); anchors.verticalCenter: parent.verticalCenter; text: page.mod.nameOf(modelData) + " · " + (modelData.kind === "mic" ? page.t("микрофон", "microphone") : page.t("камера", "camera")); color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption + 1 }
          Text {
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            text: (modelData.now ? page.t("сейчас · ", "now · ") : page.ago(modelData.last) + " · ") + page.times(modelData.count) + " · " + page.span(modelData.total)
            color: modelData.now ? page.accent : Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption
          }
        }
      }
    }
  }
}
