import QtQuick
import QtMultimedia
import qs.Commons
import "../.."
import "../../vendor/soundhub" as SH
import "../../fonts"

// Settings → Bluetooth & devices → Camera: which camera, a live preview
// (on only while you look), ready-made looks, then the picture controls.
Column {
  id: page
  property var mod: null
  spacing: SH.HubStyle.gap
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }
  property bool preview: false
  readonly property var picture: ["brightness", "contrast", "saturation", "sharpness", "gain", "backlight_compensation", "power_line_frequency"]
  readonly property var auto: ["auto_exposure", "exposure_time_absolute", "exposure_dynamic_framerate", "white_balance_automatic",
                               "white_balance_temperature", "focus_automatic_continuous", "focus_absolute"]
  readonly property var frame: ["zoom_absolute", "pan_absolute", "tilt_absolute"]
  function ctrlsOf(names) { return (mod ? mod.ctrls : []).filter(function(c) { return names.indexOf(c.name) >= 0 }) }

  component Card: SH.HubCard {
    width: page.width
    height: inner.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    default property alias content: inner.data
    Column {
      id: inner
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      spacing: Style.space(8)
    }
  }
  // one control: a switch for booleans and auto modes, a select for menus, a slider otherwise
  component Ctrl: SH.HubRow {
    id: cr
    property var c: ({})
    readonly property bool isAuto: c.name === "auto_exposure"
    title: page.mod ? page.mod.label(c.name) : c.name
    opacity: c.inactive ? 0.45 : 1
    fg: page.fg; fontFamily: page.ff
    SH.HubSwitch {
      visible: cr.c.type === "bool" || cr.isAuto || (cr.c.type === "int" && cr.c.min === 0 && cr.c.max === 1)
      checked: cr.isAuto ? cr.c.value === 3 : cr.c.value === 1
      fg: page.fg; accent: page.accent; ink: page.bgc
      onToggled: page.mod.set(cr.c.name, cr.isAuto ? (checked ? 1 : 3) : (checked ? 0 : 1))
    }
    SH.HubSelect {
      visible: cr.c.type === "menu" && !cr.isAuto
      width: Style.space(180); showLabel: false
      options: Object.keys(cr.c.menu || {}).map(function(k) { return { value: k, label: cr.c.menu[k] === "Disabled" ? page.t("Выключено", "Off") : cr.c.menu[k] } })
      value: String(cr.c.value)
      foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
      onChanged: function(v) { page.mod.set(cr.c.name, parseInt(v, 10)) }
    }
    SH.HubSlider {
      visible: cr.c.type === "int" && !(cr.c.min === 0 && cr.c.max === 1)
      enabled: !cr.c.inactive
      width: Style.space(180); minimum: cr.c.min; maximum: cr.c.max; step: cr.c.step || 1
      value: cr.c.value
      format: function(v) { return cr.c.name === "zoom_absolute" ? (v / 100).toFixed(1) + "×" : cr.c.name === "white_balance_temperature" ? Math.round(v) + " K" : Math.round(v) }
      fillColor: page.accent; fontFamily: page.ff
      onReleased: function(v) { page.mod.set(cr.c.name, Math.round(v / (cr.c.step || 1)) * (cr.c.step || 1)) }
    }
  }

  Card {
    SH.HubRow {
      icon: "\u{f05a0}"
      title: page.t("Камера", "Camera")
      fg: page.fg; fontFamily: page.ff
      SH.HubSelect {
        width: Style.space(220); showLabel: false
        options: (page.mod ? page.mod.cameras : []).map(function(c) { return { value: c.dev, label: c.name } })
        value: page.mod ? page.mod.dev : ""
        foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
        onChanged: function(v) { page.mod.dev = v }
      }
    }
    Text {
      visible: page.mod && page.mod.cameras.length === 0
      text: page.t("Камер не найдено", "No cameras found")
      color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption
    }
    // the preview: the camera is opened only while it's on
    Rectangle {
      visible: page.mod && page.mod.cameras.length > 0
      width: parent.width; height: width * 9 / 16
      radius: SH.HubStyle.radius
      color: "black"
      clip: true
      CaptureSession {
        camera: Camera {
          id: cam
          active: page.preview && page.visible
          cameraDevice: {
            var l = devices.videoInputs
            for (var i = 0; i < l.length; i++) if (String(l[i].id).indexOf(page.mod ? page.mod.dev : "~") >= 0) return l[i]
            return devices.defaultVideoInput
          }
        }
        videoOutput: vo
      }
      MediaDevices { id: devices }
      VideoOutput { id: vo; anchors.fill: parent; fillMode: VideoOutput.PreserveAspectCrop }
      Column {
        visible: !page.preview
        anchors.centerIn: parent
        spacing: Style.space(8)
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "\u{f05a0}"; color: Qt.rgba(1, 1, 1, 0.5); font.family: page.ff; font.pixelSize: Style.space(40) }
        SH.HubChip {
          anchors.horizontalCenter: parent.horizontalCenter
          icon: "\u{f040a}"; label: page.t("Включить просмотр", "Start preview")
          on: true
          fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
          onClicked: page.preview = true
        }
      }
      SH.HubChip {
        visible: page.preview
        anchors.right: parent.right; anchors.top: parent.top; anchors.margins: Style.space(10)
        iconOnly: true; icon: "\u{f04db}"; label: page.t("Остановить", "Stop")
        fg: "white"; accent: page.accent; fontFamily: page.ff
        onClicked: page.preview = false
      }
    }
    Row {
      spacing: Style.space(6)
      SH.HubChip { icon: "\u{f02cb}"; label: page.t("Для звонков", "For calls"); fg: page.fg; accent: page.accent; fontFamily: page.ff; onClicked: page.mod.cmd(["preset", page.mod.dev, "call"]) }
      SH.HubChip { icon: "\u{f0594}"; label: page.t("Тёмная комната", "Dark room"); fg: page.fg; accent: page.accent; fontFamily: page.ff; onClicked: page.mod.cmd(["preset", page.mod.dev, "dark"]) }
      SH.HubChip { icon: "\u{f099b}"; label: page.t("Как с завода", "Factory"); fg: page.fg; accent: page.accent; fontFamily: page.ff; onClicked: page.mod.cmd(["reset", page.mod.dev]) }
    }
  }
  SettingsTabs {
    id: tabs
    tabs: [{ id: "pic", label: page.t("Картинка", "Picture"), icon: "\u{f03d8}" }, { id: "auto", label: page.t("Экспозиция и фокус", "Exposure & focus"), icon: "\u{f04c5}" },
           { id: "frame", label: page.t("Кадр", "Framing"), icon: "\u{f0349}" }]
  }
  Card {
    Repeater {
      model: page.ctrlsOf(tabs.current === "pic" ? page.picture : tabs.current === "auto" ? page.auto : page.frame)
      delegate: Ctrl { required property var modelData; c: modelData }
    }
  }
}
