import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Commons
import "../.."
import "../home"

// Centre: the tab for what you switch and track — notifications on the
// left; on the right quick toggles (Bluetooth with the headphones' battery,
// night light, do not disturb, microphone, stay awake, screenshot, screen
// recording, recorder) and a timer / stopwatch. Quick toggles after the
// Control Center plugin (404Prabhat, MIT) and caelestia's utilities — ideas
// only, no code taken.
NotchModule {
  id: hm
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Центр", "Centre")
  icon: "\u{f0a1a}"
  description: t("Уведомления, быстрые переключатели и таймер", "Notifications, quick toggles and a timer")
  topTab: true
  pageWidth: 820
  page: Component { CenterPage { mod: hm } }
  function opt(key, fallback) { return notch ? notch.moduleOpt("center", key, fallback) : fallback }
  function persist(values) { if (notch) notch.modulePersist("center", values) }
  function moduleById(id) { return notch ? notch.moduleById(id) : null }

  // ------------------------------------------------------- quick toggles
  // states that live outside the shell, read every few seconds while open
  property var sys: ({})
  Process {
    id: status
    command: ["bash", "-c",
      "bt=0; omarchy-bluetooth-power is-on >/dev/null 2>&1 && bt=1; " +
      "devs=$(bluetoothctl devices Connected 2>/dev/null | while read -r _ mac name; do " +
      "  b=$(bluetoothctl info \"$mac\" 2>/dev/null | sed -n 's/.*Battery Percentage: .*(\\([0-9]*\\)).*/\\1/p'); " +
      "  printf '{\"name\":\"%s\",\"battery\":%s},' \"${name//\\\"/}\" \"${b:-null}\"; done); " +
      "night=$(omarchy toggle nightlight --status 2>/dev/null | grep -q '\"enabled\":true' && echo 1 || echo 0); " +
      "awake=0; [ -f \"$HOME/.local/state/omarchy/indicators/stay-awake\" ] && awake=1; " +
      "rec=0; pgrep -f '^gpu-screen-recorder' >/dev/null && rec=1; " +
      "wifi=; nmcli -t -f TYPE device 2>/dev/null | grep -qx wifi && wifi=$(nmcli -t radio wifi 2>/dev/null); " +
      "printf '{\"bt\":%s,\"devices\":[%s],\"night\":%s,\"awake\":%s,\"rec\":%s,\"wifi\":\"%s\"}\\n' $bt \"${devs%,}\" $night $awake $rec \"$wifi\""]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: { try { hm.sys = JSON.parse(text) } catch (e) {} } }
  }
  function refresh() { if (!status.running) status.running = true }
  Timer { interval: 3000; repeat: true; triggeredOnStart: true; running: hm.active && hm.notch !== null && (hm.notch.expanded || hm.headphoneWatch); onTriggered: hm.refresh() }
  function run(cmd) { Quickshell.execDetached(cmd); after.restart() }
  Timer { id: after; interval: 700; onTriggered: hm.refresh() }

  readonly property var source: Pipewire.defaultAudioSource
  PwObjectTracker { objects: [hm.source] }
  readonly property bool micMuted: source && source.audio ? source.audio.muted : false
  readonly property var notif: moduleById("notifications")
  readonly property var headphones: {
    var d = sys.devices || []
    for (var i = 0; i < d.length; i++) if (d[i].battery !== null) return d[i]
    return d.length ? d[0] : null
  }
  readonly property var toggles: {
    var out = []
    if (sys.wifi === "enabled" || sys.wifi === "disabled")
      out.push({ id: "wifi", icon: "\u{f05a9}", label: "Wi-Fi", on: sys.wifi === "enabled", sub: sys.wifi === "enabled" ? t("вкл", "on") : t("выкл", "off") })
    out.push({ id: "bt", icon: sys.bt ? "\u{f00af}" : "\u{f00b2}", label: "Bluetooth", on: !!sys.bt,
               sub: headphones ? headphones.name + (headphones.battery !== null ? " · " + headphones.battery + "%" : "") : (sys.bt ? t("вкл", "on") : t("выкл", "off")) })
    out.push({ id: "night", icon: "\u{f0594}", label: t("Ночной свет", "Night light"), on: !!sys.night, sub: sys.night ? t("вкл", "on") : t("выкл", "off") })
    if (notif) out.push({ id: "dnd", icon: notif.dnd ? "\u{f009b}" : "\u{f009a}", label: t("Не беспокоить", "Do not disturb"), on: notif.dnd, sub: notif.dnd ? t("вкл", "on") : t("выкл", "off") })
    out.push({ id: "mic", icon: micMuted ? "\u{f036d}" : "\u{f036c}", label: t("Микрофон", "Microphone"), on: !micMuted, sub: micMuted ? t("выключен", "muted") : t("включён", "live") })
    out.push({ id: "awake", icon: "\u{f0176}", label: t("Не засыпать", "Stay awake"), on: !!sys.awake, sub: sys.awake ? t("вкл", "on") : t("выкл", "off") })
    out.push({ id: "shot", icon: "\u{f0100}", label: t("Скриншот", "Screenshot"), on: false, sub: t("область", "region") })
    var rec = moduleById("recorder")
    if (rec && rec.active) out.push({ id: "dictaphone", icon: "\u{f036c}", label: t("Диктофон", "Recorder"), on: rec.recording,
                                      sub: rec.recording ? rec.elapsed + t(" — стоп", " — stop") : t("записать", "record") })
    out.push({ id: "rec", icon: "\u{f044b}", label: t("Запись экрана", "Screen recording"), on: !!sys.rec, sub: sys.rec ? t("идёт — стоп", "on — stop") : t("начать", "start") })
    return out
  }
  function toggle(id) {
    switch (id) {
      case "wifi": run(["nmcli", "radio", "wifi", sys.wifi === "enabled" ? "off" : "on"]); break
      case "bt": run(["omarchy-bluetooth-power", "toggle"]); break
      case "night": run(["omarchy", "toggle", "nightlight"]); break
      case "dnd": notif.setDnd(!notif.dnd); break
      case "mic": if (source && source.audio) source.audio.muted = !source.audio.muted; break
      case "awake": run(["omarchy", "toggle", "idle"]); break
      case "shot": notch.expanded = false; Quickshell.execDetached(["bash", "-c", "sleep 0.4; omarchy-capture-screenshot"]); break
      case "dictaphone": moduleById("recorder").toggleRecording(); break
      case "rec": notch.expanded = false; Quickshell.execDetached(["bash", "-c", "sleep 0.4; omarchy-capture-screenrecording" + (sys.rec ? " --stop-recording" : "")]); after.restart(); break
    }
  }

  // headphones' battery: an event once when it drops to 15 %
  readonly property bool headphoneWatch: opt("batteryEvent", true) === true
  property int lastWarned: -1
  Timer { interval: 120000; repeat: true; running: hm.active && hm.headphoneWatch && !(hm.notch && hm.notch.expanded); onTriggered: hm.refresh() }
  onHeadphonesChanged: {
    var h = headphones
    if (!h || h.battery === null || !notch) return
    if (h.battery <= 15 && (lastWarned < 0 || lastWarned > 15))
      notch.flash({ key: "headphones", icon: "\u{f02cb}", title: h.name, message: t("Заряд ", "Battery ") + h.battery + "%", ms: 6000 })
    lastWarned = h.battery
  }

  // ---------------------------------------------------- timer, stopwatch
  property string clockMode: "timer"            // timer | stopwatch
  property real timerTotal: 5 * 60000
  property real timerEnd: 0                     // ms since epoch while running
  property real timerLeft: timerTotal           // while paused
  property real swStart: 0
  property real swAcc: 0
  property real nowMs: Date.now()
  readonly property bool timerRunning: timerEnd > 0
  readonly property bool swRunning: swStart > 0
  Timer { interval: 250; repeat: true; running: hm.timerRunning || hm.swRunning; onTriggered: { hm.nowMs = Date.now(); hm.checkTimer() } }
  readonly property real remaining: timerRunning ? Math.max(0, timerEnd - nowMs) : timerLeft
  readonly property real elapsed: swAcc + (swRunning ? nowMs - swStart : 0)
  function fmt(ms) {
    var s = Math.ceil(ms / 1000), h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60), ss = s % 60
    return (h ? h + ":" + (m < 10 ? "0" : "") : "") + m + ":" + (ss < 10 ? "0" : "") + ss
  }
  function setTimer(min) { timerEnd = 0; timerTotal = min * 60000; timerLeft = timerTotal }
  function startPause() {
    nowMs = Date.now()
    if (clockMode === "timer") {
      if (timerRunning) { timerLeft = remaining; timerEnd = 0 }
      else { if (timerLeft <= 0) timerLeft = timerTotal; timerEnd = nowMs + timerLeft }
    } else {
      if (swRunning) { swAcc += nowMs - swStart; swStart = 0 } else swStart = nowMs
    }
  }
  function reset() { if (clockMode === "timer") { timerEnd = 0; timerLeft = timerTotal } else { swStart = 0; swAcc = 0 } }
  function checkTimer() {
    if (timerRunning && remaining <= 0) {
      timerEnd = 0; timerLeft = timerTotal
      if (notch) notch.flash({ key: "timer", big: true, icon: "\u{f051b}", title: t("Таймер", "Timer"),
                               message: t("Время вышло", "Time's up") + " · " + fmt(timerTotal), ms: 10000 })
      Quickshell.execDetached(["bash", "-c", "pw-play /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null || true"])
    }
  }
  // a running timer shows in the collapsed notch
  live: timerRunning || swRunning
  livePriority: 15
  liveLeft: Component { Text { text: "\u{f051b}"; color: Color.accent; font.family: Style.font.family; font.pixelSize: Style.font.body + 2 } }
  liveRight: Component {
    Text {
      text: hm.fmt(hm.timerRunning ? hm.remaining : hm.elapsed)
      color: Color.foreground
      font.family: Style.font.family; font.pixelSize: Style.font.body; font.bold: true
    }
  }
}
