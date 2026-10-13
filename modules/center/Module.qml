import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Commons
import "../.."
import "../home"
import "../../fonts"

// Centre: the control centre — network and Bluetooth tiles with their short
// lists, switches (do not disturb, night light, stay awake, headphones),
// sliders for volume, microphone and brightness with a device
// picker, tools with a timer / stopwatch / pomodoro, and the
// notifications folded at the bottom (CenterPage). Quick toggles after the
// Control Center plugin (404Prabhat, MIT) and caelestia's utilities — ideas
// only, no code taken.
NotchModule {
  id: hm
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Центр", "Centre")
  icon: "\u{f0a1a}"
  description: t("Пункт управления: сеть, Bluetooth, звук, яркость, инструменты, уведомления", "Control centre: network, Bluetooth, sound, brightness, tools, notifications")
  topTab: true
  pageWidth: 780
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
      "night=$(omarchy toggle nightlight --status 2>/dev/null | grep -q '\"enabled\":true' && echo 1 || echo 0); " +
      "awake=0; [ -f \"$HOME/.local/state/omarchy/indicators/stay-awake\" ] && awake=1; " +
      "rec=0; pgrep -f '^gpu-screen-recorder' >/dev/null && rec=1; " +
      "printf '{\"night\":%s,\"awake\":%s,\"rec\":%s}\\n' $night $awake $rec"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: { try { hm.sys = JSON.parse(text) } catch (e) {} } }
  }
  function refresh() { if (!status.running) status.running = true }
  Timer { interval: 6000; repeat: true; triggeredOnStart: true; running: hm.active && hm.notch !== null && hm.notch.expanded; onTriggered: hm.refresh() }
  function run(cmd) { Quickshell.execDetached(cmd); after.restart() }
  Timer { id: after; interval: 700; onTriggered: hm.refresh() }

  readonly property var source: Pipewire.defaultAudioSource
  PwObjectTracker { objects: [hm.source] }
  readonly property bool micMuted: source && source.audio ? source.audio.muted : false
  readonly property var notif: moduleById("notifications")
  // Bluetooth comes from the Devices module (one bluetoothctl reader, not two)
  readonly property var dv: moduleById("devices")
  // Wi-Fi, live from the Network module (NetworkManager): "enabled" | "disabled" | "" (no Wi-Fi card)
  readonly property var nwm: moduleById("network")
  readonly property string wifiState: nwm && nwm.wifiDev ? (nwm.wifiOn ? "enabled" : "disabled") : ""
  readonly property bool btOn: !!(dv && dv.st && dv.st.bt && dv.st.bt.powered)
  readonly property var btConnected: dv && dv.st && dv.st.devices ? dv.st.devices.filter(function(x) { return x.connected }).map(function(x) { return { name: x.name, battery: x.battery === undefined ? null : x.battery } }) : []
  readonly property var headphones: {
    var d = btConnected
    for (var i = 0; i < d.length; i++) if (d[i].battery !== null) return d[i]
    return d.length ? d[0] : null
  }
  readonly property var toggles: {
    var out = []
    if (wifiState === "enabled" || wifiState === "disabled")
      out.push({ id: "wifi", icon: "\u{f05a9}", label: "Wi-Fi", on: wifiState === "enabled", sub: wifiState === "enabled" ? t("вкл", "on") : t("выкл", "off") })
    out.push({ id: "bt", icon: btOn ? "\u{f00af}" : "\u{f00b2}", label: "Bluetooth", on: btOn,
               sub: headphones ? headphones.name + (headphones.battery !== null ? " · " + headphones.battery + "%" : "") : (btOn ? t("вкл", "on") : t("выкл", "off")) })
    var hph = moduleById("headphones")
    if (hph && hph.active && hph.present)
      out.push({ id: "hp", icon: hph.modeIcon(hph.mode), label: hph.st.model || t("Наушники", "Headphones"), on: hph.mode !== "off",
                 sub: hph.modeName(hph.mode) + (hph.st.battery !== undefined ? " · " + hph.st.battery + "%" : "") })
    out.push({ id: "night", icon: "\u{f0594}", label: t("Ночной свет", "Night light"), on: !!sys.night, sub: sys.night ? t("вкл", "on") : t("выкл", "off") })
    if (notif) out.push({ id: "dnd", icon: notif.dnd ? "\u{f009b}" : "\u{f009a}", label: t("Не беспокоить", "Do not disturb"), on: notif.dnd, sub: notif.dnd ? t("вкл", "on") : t("выкл", "off") })
    out.push({ id: "mic", icon: micMuted ? "\u{f036d}" : "\u{f036c}", label: t("Микрофон", "Microphone"), on: !micMuted, sub: micMuted ? t("выключен", "muted") : t("включён", "live") })
    out.push({ id: "awake", icon: "\u{f0176}", label: t("Не засыпать", "Stay awake"), on: !!sys.awake, sub: sys.awake ? t("вкл", "on") : t("выкл", "off") })
    var sm = moduleById("screenshot")
    out.push({ id: "shot", icon: "\u{f0100}", label: t("Скриншот", "Screenshot"), on: false,
               sub: sm ? ({ region: t("область", "region"), windows: t("окно", "window"), fullscreen: t("весь экран", "screen"), smart: t("умный", "smart") }[sm.mode] || "") + (sm.delay ? " · " + sm.delay + t(" с", " s") : "") : t("область", "region") })
    var rec = moduleById("recorder")
    if (rec && rec.active) out.push({ id: "dictaphone", icon: "\u{f036c}", label: t("Диктофон", "Recorder"), on: rec.recording,
                                      sub: rec.recording ? rec.elapsed + t(" — стоп", " — stop") : t("записать", "record") })
    out.push({ id: "rec", icon: "\u{f044b}", label: t("Запись экрана", "Screen recording"), on: !!sys.rec, sub: sys.rec ? t("идёт — стоп", "on — stop") : t("начать", "start") })
    return out
  }
  function toggle(id) {
    switch (id) {
      case "wifi": if (nwm) nwm.setRadio(wifiState !== "enabled"); break
      case "bt": if (dv && dv.adapter) dv.adapter.enabled = !dv.adapter.enabled; break
      case "hp": moduleById("headphones").cmd(["cycle"]); break
      case "night": run(["omarchy", "toggle", "nightlight"]); break
      case "dnd": notif.setDnd(!notif.dnd); break
      case "mic": if (source && source.audio) source.audio.muted = !source.audio.muted; break
      case "awake": run(["omarchy", "toggle", "idle"]); break
      case "shot": { var ss = moduleById("screenshot"); if (ss && ss.active) ss.shoot(); else { notch.expanded = false; Quickshell.execDetached(["bash", "-c", "sleep 0.4; omarchy-capture-screenshot"]) } } break
      case "dictaphone": moduleById("recorder").toggleRecording(); break
      case "rec": notch.expanded = false; Quickshell.execDetached(["bash", "-c", "sleep 0.4; omarchy-capture-screenrecording" + (sys.rec ? " --stop-recording" : "")]); after.restart(); break
    }
  }

  // headphones' battery: an event once when it drops to 15 %
  readonly property bool headphoneWatch: opt("batteryEvent", true) === true
  property int lastWarned: -1
  // (the battery arrives live from BlueZ through Devices — no polling)
  onHeadphonesChanged: {
    var h = headphones
    if (!h || h.battery === null || !notch) return
    if (h.battery <= 15 && (lastWarned < 0 || lastWarned > 15))
      notch.flash({ key: "headphones", icon: "\u{f02cb}", title: h.name, message: t("Заряд ", "Battery ") + h.battery + "%", ms: 6000 })
    lastWarned = h.battery
  }

  // ---------------------------------------------------- timer, stopwatch
  property string clockMode: "timer"            // timer | stopwatch | pomodoro
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
  // ------------------------------------------------------------ pomodoro
  // Work, a short break, again; every Nth break a long one. On a break the
  // screen dims ("take a break", skippable) and the Focus sounds stop; they
  // start again with the next work round. After Omadoro (klaudworks) and
  // Pomodoro (rokan00) — the idea, not their code.
  readonly property var pomo: Object.assign({ work: 25, short: 5, long: 15, cycles: 4, overlay: true, sounds: false, autoNext: true }, opt("pomodoro", ({})))
  function setPomo(v) { persist({ pomodoro: Object.assign({}, pomo, v) }) }
  property string phase: "idle"                 // idle | work | short | long
  property int done: 0                          // work rounds finished
  property real phaseEnd: 0
  property real phaseLeft: 0
  readonly property bool pomoRunning: phaseEnd > 0
  readonly property real pomoRemaining: pomoRunning ? Math.max(0, phaseEnd - nowMs) : phaseLeft
  readonly property bool onBreak: phase === "short" || phase === "long"
  Timer { interval: 250; repeat: true; running: hm.pomoRunning; onTriggered: { hm.nowMs = Date.now(); hm.checkPomo() } }
  function minutesOf(ph) { return ph === "work" ? pomo.work : ph === "short" ? pomo.short : pomo.long }
  function startPhase(ph) {
    phase = ph; nowMs = Date.now()
    phaseEnd = nowMs + minutesOf(ph) * 60000
    var snd = moduleById("soundhub")
    if (pomo.sounds && snd && snd.ambient) { if (ph === "work" && snd.ambient.selectedCount() > 0) snd.ambient.playAll(); else if (ph !== "work") snd.ambient.stopAll() }
  }
  function pomoStartPause() {
    nowMs = Date.now()
    if (phase === "idle") { startPhase("work"); return }
    if (pomoRunning) { phaseLeft = pomoRemaining; phaseEnd = 0 }
    else phaseEnd = nowMs + (phaseLeft > 0 ? phaseLeft : minutesOf(phase) * 60000)
  }
  function pomoReset() {
    phase = "idle"; phaseEnd = 0; phaseLeft = 0; done = 0
    var snd = moduleById("soundhub"); if (pomo.sounds && snd && snd.ambient) snd.ambient.stopAll()
  }
  function skipBreak() { if (onBreak) startPhase("work") }
  function checkPomo() {
    if (!pomoRunning || pomoRemaining > 0) return
    var next
    if (phase === "work") { done += 1; next = done % pomo.cycles === 0 ? "long" : "short" }
    else next = "work"
    if (notch) notch.flash({ key: "pomodoro", big: true, icon: next === "work" ? "\u{f09d1}" : "\u{f0176}",
                             title: next === "work" ? t("Перерыв окончен", "Break's over") : t("Время отдохнуть", "Time for a break"),
                             message: next === "work" ? t("Следующий круг работы", "The next work round") : t("Кругов сделано: ", "Rounds done: ") + done, ms: 8000 })
    Quickshell.execDetached(["bash", "-c", "pw-play /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null || true"])
    if (pomo.autoNext) startPhase(next)
    else { phase = next; phaseEnd = 0; phaseLeft = minutesOf(next) * 60000 }
  }
  function phaseName(ph) { return { idle: t("Готов", "Ready"), work: t("Работа", "Work"), short: t("Перерыв", "Break"), long: t("Длинный перерыв", "Long break") }[ph] }

  // the break screen: dims every monitor, a skip button
  Variants {
    model: hm.active && hm.onBreak && hm.pomoRunning && hm.pomo.overlay ? Quickshell.screens : []
    delegate: BreakOverlay { required property var modelData; screen: modelData; mod: hm }
  }

  // a running timer shows in the collapsed notch
  live: timerRunning || swRunning || phase !== "idle"
  livePriority: 15
  liveLeft: Component { Text { text: hm.phase === "work" ? "\u{f09d1}" : hm.onBreak ? "\u{f0176}" : "\u{f051b}"; color: Color.accent; font.family: Fonts.ui; font.pixelSize: Style.font.body + 2 } }
  liveRight: Component {
    Text {
      text: hm.phase !== "idle" && !hm.timerRunning && !hm.swRunning ? hm.fmt(hm.pomoRemaining) + (hm.pomoRunning ? "" : "  ⏸")
            : hm.fmt(hm.timerRunning ? hm.remaining : hm.elapsed)
      color: Color.foreground
      font.family: Fonts.ui; font.pixelSize: Style.font.body; font.bold: true
    }
  }
}
