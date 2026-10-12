import QtQuick
import Quickshell.Widgets
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// Settings → Personalisation → Lock screen: three cards; the one in use is
// ringed. Switching restarts the shell (the lock handler swaps then).
Column {
  id: page
  property var mod: null
  spacing: SH.HubStyle.gap
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }
  readonly property var info: ({
    "omarchy.lock": { name: page.t("Стандартный", "Standard"), what: page.t("Экран блокировки Omarchy в цветах темы", "Omarchy's lock screen in the theme's colours") },
    "io.github.smoothpixels.lock-designs": { name: "Lock Designs", what: page.t("66 дизайнов на выбор, есть видео-фоны · SmoothPixels", "66 designs to pick from, some with video · SmoothPixels") },
    "io.github.the4rchangel.hackery-lock": { name: "Hackery Lock", what: page.t("Терминал: матрица, лог загрузки, приглашение shell · the4rchangel", "A terminal: matrix rain, boot log, a shell prompt · the4rchangel") }
  })
  readonly property bool anyOn: mod ? mod.locks.some(function(l) { return l.enabled }) : false

  Row {
    width: page.width
    spacing: Style.space(10)
    Repeater {
      model: page.mod ? page.mod.locks : []
      delegate: Rectangle {
        id: card
        required property var modelData
        readonly property bool inUse: modelData.enabled
        readonly property bool working: page.mod.busy === modelData.id
        width: (page.width - Style.space(20)) / 3
        height: col.implicitHeight + Style.space(16)
        radius: SH.HubStyle.radius + Style.space(2)
        color: SH.HubStyle.tint(page.fg, 0.05)
        border.width: inUse ? 2 : 0; border.color: page.accent
        Column {
          id: col
          x: Style.space(8); y: Style.space(8)
          width: parent.width - Style.space(16)
          spacing: Style.space(8)
          ClippingRectangle {
            width: parent.width; height: width * 0.56
            radius: SH.HubStyle.radius
            color: SH.HubStyle.tint(page.accent, 0.18)
            Image { anchors.fill: parent; visible: !!card.modelData.preview; source: card.modelData.preview ? "file://" + card.modelData.preview : ""; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 480 }
            Column {
              visible: !card.modelData.preview
              anchors.centerIn: parent
              spacing: Style.space(4)
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatTime(new Date(), "HH:mm"); color: page.fg; font.family: page.ff; font.pixelSize: Style.space(30); font.bold: true }
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: "\u{f033e}"; color: page.accent; font.family: page.ff; font.pixelSize: Style.space(18) }
            }
          }
          Row {
            spacing: Style.space(6)
            Text { text: page.info[card.modelData.id].name; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.body; font.bold: true }
            Text { visible: card.inUse; anchors.verticalCenter: parent.verticalCenter; text: page.t("· сейчас", "· in use"); color: page.accent; font.family: page.ff; font.pixelSize: Style.font.caption - 1 }
          }
          Text { width: parent.width; wrapMode: Text.Wrap; text: page.info[card.modelData.id].what; color: Qt.darker(page.fg, 1.5); font.family: page.ff; font.pixelSize: Style.font.caption - 1 }
          Flow {
            width: parent.width
            spacing: Style.space(4)
            SH.HubChip {
              visible: !card.inUse
              icon: card.working ? "\u{f0450}" : card.modelData.installed ? "\u{f012c}" : "\u{f01da}"
              label: card.working ? page.t("Подождите…", "Wait…") : card.modelData.installed ? page.t("Использовать", "Use") : page.t("Установить", "Install")
              on: true; h: Style.space(26)
              fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
              onClicked: if (!page.mod.busy) page.mod.run([card.modelData.installed ? "use" : "install", card.modelData.id])
            }
            SH.HubChip {
              visible: card.inUse
              icon: "\u{f0208}"; label: page.t("Проверить", "Preview")
              h: Style.space(26)
              fg: page.fg; accent: page.accent; fontFamily: page.ff
              onClicked: page.mod.cmd(["preview"])
            }
            SH.HubChip {
              visible: card.inUse && card.modelData.id === "io.github.smoothpixels.lock-designs"
              icon: "\u{f03d8}"; label: page.t("Дизайн…", "Design…")
              h: Style.space(26)
              fg: page.fg; accent: page.accent; fontFamily: page.ff
              onClicked: { page.mod.notch.settingsOpen = false; page.mod.cmd(["explore"]) }
            }
          }
        }
      }
    }
  }
  Text {
    width: page.width; wrapMode: Text.Wrap
    text: page.t("Включён только один экран блокировки. После переключения оболочка перезапустится. «Проверить» показывает экран без блокировки — щёлкните, чтобы закрыть.",
                 "Only one lock screen is on. Switching restarts the shell. Preview shows it without locking — click to close.")
    color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption - 1
  }
}
