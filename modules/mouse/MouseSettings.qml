import QtQuick
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// Settings → Bluetooth & devices → Logitech mouse: per device — battery,
// DPI (with quick steps), SmartShift, the wheel's mode and direction, the
// thumb wheel.
Column {
  id: page
  property var mod: null
  spacing: SH.HubStyle.gap
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }

  Text {
    visible: page.mod && page.mod.devices.length === 0
    width: parent.width; wrapMode: Text.Wrap
    text: page.mod && page.mod.loading ? page.t("Ищу мыши Logitech… (Solaar отвечает несколько секунд)", "Looking for Logitech mice… (Solaar takes a few seconds)")
                                       : page.t("Мышей Logitech на связи нет. Пошевелите мышью, чтобы она проснулась.", "No Logitech mouse online. Move it to wake it up.")
    color: Qt.darker(page.fg, 1.5); font.family: page.ff; font.pixelSize: Style.font.caption
  }
  Repeater {
    model: page.mod ? page.mod.devices : []
    delegate: SH.HubCard {
      id: card
      required property var modelData
      readonly property var s: modelData.settings || ({})
      width: page.width
      height: col.implicitHeight + SH.HubStyle.pad * 2
      fg: page.fg; accent: page.accent
      Column {
        id: col
        x: SH.HubStyle.pad; y: SH.HubStyle.pad
        width: parent.width - SH.HubStyle.pad * 2
        spacing: Style.space(8)
        Item {
          width: parent.width; height: Style.space(44)
          Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(12)
            Text { anchors.verticalCenter: parent.verticalCenter; text: "\u{f037d}"; color: page.accent; font.family: page.ff; font.pixelSize: Style.space(28) }
            Column {
              anchors.verticalCenter: parent.verticalCenter
              Text { text: card.modelData.name; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.body + 1; font.bold: true }
              Text {
                text: card.modelData.battery !== null ? page.t("Заряд ", "Battery ") + card.modelData.battery + "%" + (card.modelData.charging ? page.t(" · заряжается", " · charging") : "") : ""
                color: card.modelData.battery !== null && card.modelData.battery <= 15 ? Color.urgent : Qt.darker(page.fg, 1.4)
                font.family: page.ff; font.pixelSize: Style.font.caption
              }
            }
          }
          Text {
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            visible: page.mod && page.mod.loading
            text: "\u{f051f}"; color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.body
          }
        }
        SH.HubRow {
          visible: card.s.dpi !== undefined
          icon: "\u{f04c5}"
          title: page.t("Чувствительность", "Sensitivity"); hint: card.s.dpi + " DPI"
          fg: page.fg; fontFamily: page.ff
          SH.HubSlider {
            width: Style.space(200); minimum: 200; maximum: 8000; step: 50
            value: Number(card.s.dpi || 1000)
            format: function(v) { return Math.round(v / 50) * 50 }
            fillColor: page.accent; fontFamily: page.ff
            onReleased: function(v) { page.mod.set(card.modelData.name, "dpi", Math.round(v / 50) * 50) }
          }
        }
        Row {
          visible: card.s.dpi !== undefined
          spacing: Style.space(6)
          Repeater {
            model: [800, 1000, 1600, 2400, 3200, 4000]
            delegate: SH.HubChip {
              required property int modelData
              label: String(modelData)
              on: card.s.dpi === modelData
              subtle: true
              h: Style.space(24)
              fg: page.fg; accent: page.accent; fontFamily: page.ff
              onClicked: page.mod.set(card.modelData.name, "dpi", modelData)
            }
          }
        }
        SH.HubRow {
          visible: card.s["scroll-ratchet"] !== undefined
          icon: "\u{f0d76}"
          title: page.t("Колесо", "Wheel"); hint: page.t("С щелчками или свободное вращение", "Clicky or free-spinning")
          fg: page.fg; fontFamily: page.ff
          SH.HubSelect {
            width: Style.space(200); showLabel: false
            options: [{ value: "Ratcheted", label: page.t("С щелчками", "Ratcheted") }, { value: "Freespinning", label: page.t("Свободное", "Free-spinning") }]
            value: String(card.s["scroll-ratchet"] || "Ratcheted")
            foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
            onChanged: function(v) { page.mod.set(card.modelData.name, "scroll-ratchet", v) }
          }
        }
        SH.HubRow {
          visible: card.s["smart-shift"] !== undefined
          title: "SmartShift"; hint: page.t("Скорость прокрутки, после которой колесо само раскручивается (50 — никогда)", "Spin speed at which the wheel frees itself (50 — never)")
          fg: page.fg; fontFamily: page.ff
          SH.HubSlider {
            width: Style.space(200); minimum: 1; maximum: 50; step: 1
            value: Number(card.s["smart-shift"] || 10)
            format: function(v) { return Math.round(v) }
            fillColor: page.accent; fontFamily: page.ff
            onReleased: function(v) { page.mod.set(card.modelData.name, "smart-shift", Math.round(v)) }
          }
        }
        SH.HubRow {
          visible: card.s["hires-smooth-invert"] !== undefined
          title: page.t("Обратная прокрутка колеса", "Invert the wheel"); fg: page.fg; fontFamily: page.ff
          SH.HubSwitch { checked: card.s["hires-smooth-invert"] === true; fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.mod.set(card.modelData.name, "hires-smooth-invert", !checked) }
        }
        SH.HubRow {
          visible: card.s["hires-smooth-resolution"] !== undefined
          title: page.t("Плавная прокрутка высокой точности", "High-resolution scrolling"); fg: page.fg; fontFamily: page.ff
          SH.HubSwitch { checked: card.s["hires-smooth-resolution"] === true; fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.mod.set(card.modelData.name, "hires-smooth-resolution", !checked) }
        }
        SH.HubRow {
          visible: card.s["thumb-scroll-invert"] !== undefined
          title: page.t("Обратное боковое колесо", "Invert the thumb wheel"); fg: page.fg; fontFamily: page.ff
          SH.HubSwitch { checked: card.s["thumb-scroll-invert"] === true; fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.mod.set(card.modelData.name, "thumb-scroll-invert", !checked) }
        }
      }
    }
  }
  Text {
    visible: !!(page.mod && page.mod.error)
    width: parent.width; wrapMode: Text.Wrap
    text: page.mod ? page.mod.error : ""
    color: Color.urgent; font.family: page.ff; font.pixelSize: Style.font.caption
  }
}
