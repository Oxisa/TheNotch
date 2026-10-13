import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Commons
import "../.."

// Windows (Personalisation): how Hyprland draws windows — rounding,
// opacity of the active and the other windows, gaps, border, blur — applied
// live and kept in a "thenotch-look" block in ~/.config/hypr/looknfeel.lua;
// and the desktop widgets step aside while windows cover the screen.
NotchModule {
  id: wl
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Окна", "Windows")
  icon: "\u{f05b2}"
  description: t("Скругление, прозрачность, отступы окон; виджеты прячутся под окнами", "Window rounding, opacity, gaps; widgets step aside under windows")
  inRail: false
  core: true
  settingsSection: "personal"
  sectionOrder: 2
  settingsPage: Component { WindowsSettings { mod: wl } }
  function opt(key, fallback) { return notch ? notch.moduleOpt("windows", key, fallback) : fallback }
  function persist(values) { if (notch) notch.modulePersist("windows", values) }

  // ------------------------------------------------------------- the look
  // what Hyprland uses now, read once; our saved values win
  property var live: ({})
  Process {
    running: true
    command: ["bash", "-c", "for o in decoration:rounding decoration:active_opacity decoration:inactive_opacity general:gaps_in general:gaps_out general:border_size decoration:blur:enabled; do printf '%s ' \"$o\"; hyprctl getoption \"$o\" | head -1; done"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var o = {}
        String(text).split("\n").forEach(function(l) {
          var m = l.match(/^(\S+) (\w+): (.*)$/); if (!m) return
          var v = m[3].trim(), n = parseFloat(v)
          o[m[1]] = m[2] === "custom" ? parseFloat(v.split(" ")[0]) : m[2] === "bool" ? v === "true" : n
        })
        wl.live = o
      }
    }
  }
  readonly property var look: opt("look", ({}))
  function val(key, fallback) { return look[key] !== undefined ? look[key] : (live[key] !== undefined ? live[key] : fallback) }
  // one key changed: apply it now, save, rewrite the block
  function setLook(key, v) {
    var l = Object.assign({}, look); l[key] = v
    persist({ look: l })
    Quickshell.execDetached(["hyprctl", "eval", luaOf(l)])
    writeBlock(l)
  }
  function luaOf(l) {
    var d = [], g = [], b = []
    if (l["decoration:rounding"] !== undefined) d.push("rounding = " + Math.round(l["decoration:rounding"]))
    if (l["decoration:active_opacity"] !== undefined) d.push("active_opacity = " + Number(l["decoration:active_opacity"]).toFixed(2))
    if (l["decoration:inactive_opacity"] !== undefined) d.push("inactive_opacity = " + Number(l["decoration:inactive_opacity"]).toFixed(2))
    if (l["decoration:blur:enabled"] !== undefined) d.push("blur = { enabled = " + (l["decoration:blur:enabled"] ? "true" : "false") + " }")
    if (l["general:gaps_in"] !== undefined) g.push("gaps_in = " + Math.round(l["general:gaps_in"]))
    if (l["general:gaps_out"] !== undefined) g.push("gaps_out = " + Math.round(l["general:gaps_out"]))
    if (l["general:border_size"] !== undefined) g.push("border_size = " + Math.round(l["general:border_size"]))
    var parts = []
    if (d.length) parts.push("decoration = { " + d.join(", ") + " }")
    if (g.length) parts.push("general = { " + g.join(", ") + " }")
    return parts.length ? "hl.config({ " + parts.join(", ") + " })" : ""
  }
  readonly property string lookFile: Quickshell.env("HOME") + "/.config/hypr/looknfeel.lua"
  function writeBlock(l) {
    Quickshell.execDetached(["python3", "-I", "-c",
      "import re,sys\np,body=sys.argv[1],sys.argv[2]\ns=open(p).read()\n" +
      "s=re.sub(r'\\n?-- BEGIN thenotch-look.*?-- END thenotch-look\\n?','\\n',s,flags=re.S).rstrip('\\n')+'\\n'\n" +
      "if body: s+='\\n-- BEGIN thenotch-look\\n-- Written by TheNotch (Settings → Personalisation → Windows). Edit there, or delete this block.\\n'+body+'\\n-- END thenotch-look\\n'\n" +
      "open(p,'w').write(s)", lookFile, luaOf(l)])
  }
  function resetLook() { persist({ look: ({}) }); writeBlock({}); Quickshell.execDetached(["hyprctl", "reload"]) }

  // --------------------------------------------- widgets under windows
  // A monitor is "covered" when the windows of its workspace take 80 % of it
  // or one is full screen; widgets there fade out (WidgetWindow asks).
  readonly property bool hideCovered: active && opt("hideCovered", true) !== false
  property var covered: ({})
  // Event-driven: Hyprland says when windows change; reading all windows on a
  // timer leaked memory (≈11 MB a minute in Quickshell's IPC objects).
  // A slow check covers what has no event (a floating window resized).
  Timer { interval: 30000; repeat: true; triggeredOnStart: true; running: wl.hideCovered; onTriggered: after.restart() }
  Connections { target: Hyprland; enabled: wl.hideCovered; function onRawEvent(ev) { if (/^(openwindow|closewindow|movewindow|workspace|focusedmon|fullscreen|changefloatingmode|monitoradded|monitorremoved)/.test(ev.name)) after.restart() } }
  Timer { id: after; interval: 300; onTriggered: { Hyprland.refreshToplevels(); wl.measure() } }
  function measure() {
    var out = {}, ms = Hyprland.monitors.values
    for (var i = 0; i < ms.length; i++) {
      var m = ms[i], ws = m.activeWorkspace, sc = m.scale || 1
      if (!ws) continue
      var W = m.width / sc, H = m.height / sc, area = 0, full = false
      var tls = ws.toplevels ? ws.toplevels.values : []
      for (var j = 0; j < tls.length; j++) {
        var o = tls[j].lastIpcObject || {}
        if (o.fullscreen) full = true
        if (!o.at || !o.size || o.hidden) continue
        // the part of the window on this monitor
        var x1 = Math.max(o.at[0], m.x), y1 = Math.max(o.at[1], m.y)
        var x2 = Math.min(o.at[0] + o.size[0], m.x + W), y2 = Math.min(o.at[1] + o.size[1], m.y + H)
        if (x2 > x1 && y2 > y1) area += (x2 - x1) * (y2 - y1)
      }
      out[m.name] = full || area / (W * H) >= 0.8
    }
    covered = out
  }
  function isCovered(screenName) { return hideCovered && covered[screenName] === true }
}
