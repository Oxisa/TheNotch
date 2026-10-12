import QtQuick
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// Settings → Personalisation → Windows: Hyprland's window look as sliders
// (applied as you let go) and the widgets-under-windows switch.
Column {
  id: page
  property var mod: null
  spacing: SH.HubStyle.gap
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }

  component Knob: SH.HubRow {
    id: kn
    property string key: ""
    property real lo: 0
    property real hi: 1
    property real step: 1
    property real fallback: 0
    property bool percent: false
    width: parent ? parent.width : 0
    fg: page.fg; fontFamily: page.ff
    SH.HubSlider {
      width: Style.space(220)
      minimum: kn.lo; maximum: kn.hi; step: kn.step
      value: page.mod ? Number(page.mod.val(kn.key, kn.fallback)) : kn.fallback
      format: function(v) { return kn.percent ? Math.round(v * 100) + "%" : Math.round(v) + (kn.key === "decoration:rounding" || kn.key.indexOf("gaps") >= 0 || kn.key.indexOf("border") >= 0 ? " px" : "") }
      onReleased: function(v) { page.mod.setLook(kn.key, kn.step < 1 ? Math.round(v * 100) / 100 : Math.round(v)) }
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
      SH.HubCaption { text: page.t("Окна Hyprland", "Hyprland windows"); icon: "\u{f05b2}"; fg: page.fg; fontFamily: page.ff }
      Knob { key: "decoration:rounding"; title: page.t("Скругление углов", "Corner rounding"); lo: 0; hi: 30; fallback: 0 }
      Knob { key: "decoration:active_opacity"; title: page.t("Прозрачность активного окна", "Active window opacity"); hint: page.t("100% — непрозрачное", "100% — opaque"); lo: 0.5; hi: 1; step: 0.01; fallback: 1; percent: true }
      Knob { key: "decoration:inactive_opacity"; title: page.t("Прозрачность остальных окон", "Other windows' opacity"); lo: 0.5; hi: 1; step: 0.01; fallback: 1; percent: true }
      Knob { key: "general:gaps_in"; title: page.t("Отступ между окнами", "Gap between windows"); lo: 0; hi: 30; fallback: 5 }
      Knob { key: "general:gaps_out"; title: page.t("Отступ от краёв экрана", "Gap to the screen edges"); lo: 0; hi: 40; fallback: 10 }
      Knob { key: "general:border_size"; title: page.t("Толщина рамки", "Border width"); lo: 0; hi: 6; fallback: 2 }
      SH.HubRow {
        width: parent.width
        title: page.t("Размытие под прозрачными окнами", "Blur behind see-through windows"); hint: page.t("Нагружает видеокарту чуть сильнее", "A little more work for the GPU")
        fg: page.fg; fontFamily: page.ff
        SH.HubSwitch { checked: !!(page.mod && page.mod.val("decoration:blur:enabled", false)); fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.mod.setLook("decoration:blur:enabled", !checked) }
      }
      SH.HubChip { icon: "\u{f0450}"; label: page.t("Как в теме Omarchy", "Back to Omarchy's"); subtle: true; h: Style.space(26); fg: page.fg; accent: page.accent; fontFamily: page.ff; onClicked: page.mod.resetLook() }
    }
  }
  SH.HubCard {
    width: page.width
    height: c2.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    SH.HubRow {
      id: c2
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      icon: "\u{f0a1a}"
      title: page.t("Прятать виджеты под окнами", "Hide widgets under windows")
      hint: page.t("Когда окна стола закрывают 80% монитора или окно во весь экран — виджеты этого монитора растворяются и не просвечивают", "When a workspace's windows cover 80% of the monitor or one is full screen, that monitor's widgets fade out and don't show through")
      fg: page.fg; fontFamily: page.ff
      SH.HubSwitch { checked: !!(page.mod && page.mod.hideCovered); fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.mod.persist({ hideCovered: !page.mod.hideCovered }) }
    }
  }
}
