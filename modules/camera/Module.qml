import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."

// Webcams: a live preview right in the settings, the picture controls
// (brightness, contrast, white balance, exposure, focus, zoom…) through V4L2,
// and two ready-made looks. bin/camctl does the work.
NotchModule {
  id: cm
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Камера", "Camera")
  icon: "\u{f05a0}"
  description: t("Просмотр и настройка картинки веб-камеры", "Webcam preview and picture settings")
  inRail: false
  settingsSection: "bluetooth"
  sectionOrder: 4
  settingsPage: Component { CameraSettings { mod: cm } }

  readonly property string bin: decodeURIComponent(Qt.resolvedUrl("bin/camctl").toString().replace(/^file:\/\//, ""))
  property var cameras: []
  property string dev: ""
  property var ctrls: []
  property var queue: []
  Process {
    id: proc
    property var args: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var d = JSON.parse(text)
          if (proc.args[0] === "list") { cm.cameras = d.cameras || []; if (!cm.dev && cm.cameras.length) cm.dev = cm.cameras[0].dev }
          else if (proc.args[0] === "ctrls") cm.ctrls = d.ctrls || []
          else if (proc.args[0] !== "set") cm.cmd(["ctrls", cm.dev])
        } catch (e) {}
        cm.next()
      }
    }
  }
  function next() {
    if (proc.running || !queue.length) return
    proc.args = queue[0]; queue = queue.slice(1)
    proc.command = [bin].concat(proc.args); proc.running = true
  }
  function cmd(args) { queue = queue.concat([args]); next() }
  onDevChanged: if (dev) cmd(["ctrls", dev])
  function set(name, value) {
    ctrls = ctrls.map(function(c) { return c.name === name ? Object.assign({}, c, { value: value }) : c })
    cmd(["set", dev, name, String(value)])
    // auto modes switch other controls on and off
    if (["auto_exposure", "white_balance_automatic", "focus_automatic_continuous"].indexOf(name) >= 0) cmd(["ctrls", dev])
  }
  readonly property bool watching: active && notch !== null && notch.settingsOpen && notch.settingsSection === "bluetooth"
  onWatchingChanged: if (watching) cmd(["list"])

  // control names people understand
  function label(n) {
    var m = {
      brightness: t("Яркость", "Brightness"), contrast: t("Контраст", "Contrast"), saturation: t("Насыщенность", "Saturation"),
      sharpness: t("Резкость", "Sharpness"), gain: t("Усиление (для темноты)", "Gain (for the dark)"),
      white_balance_automatic: t("Автобаланс белого", "Auto white balance"), white_balance_temperature: t("Тёплый — холодный", "Warm — cool"),
      auto_exposure: t("Автоэкспозиция", "Auto exposure"), exposure_time_absolute: t("Выдержка", "Exposure"),
      exposure_dynamic_framerate: t("Снижать частоту кадров в темноте", "Lower the frame rate in the dark"),
      focus_automatic_continuous: t("Автофокус", "Autofocus"), focus_absolute: t("Фокус", "Focus"), zoom_absolute: t("Зум", "Zoom"),
      pan_absolute: t("Сдвиг по горизонтали", "Pan"), tilt_absolute: t("Сдвиг по вертикали", "Tilt"),
      backlight_compensation: t("Компенсация засветки сзади", "Backlight compensation"), power_line_frequency: t("Против мерцания ламп", "Anti-flicker")
    }
    return m[n] || n
  }
}
