import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Commons
import "../.."
import "../../fonts"

// Workspaces: every monitor's workspaces with live window previews — a tab
// in the open notch and a full-screen overview (Super + `, IPC "overview").
// Click a workspace or a window to go there, drag a window onto another
// workspace to move it, name a workspace and pick its tiling mode
// (dwindle, master, scrolling). Ideas from Aerial (ReidenXerx), Workspace
// Switcher (antoniowav), Workspace icons (tjcelaya) and Omarchy Modes
// Switcher (v3moreno), all MIT — the ideas, not their code.
NotchModule {
  id: wm
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Столы", "Spaces")
  icon: "\u{f0570}"
  description: t("Рабочие столы: обзор окон, перенос, имена и раскладки", "Workspaces: window overview, moving, names and tiling modes")
  topTab: true
  pageWidth: 900
  page: Component { WorkspacesPage { mod: wm } }
  settingsSection: "workspaces"
  sectionOrder: 0
  settingsPage: Component { WorkspacesSettings { mod: wm } }
  function opt(key, fallback) { return notch ? notch.moduleOpt("workspaces", key, fallback) : fallback }
  function persist(values) { if (notch) notch.modulePersist("workspaces", values) }

  // ------------------------------------------------------------- data
  readonly property var monitors: Hyprland.monitors.values.slice().sort(function(a, b) { return a.x - b.x || a.y - b.y })
  readonly property var workspaces: Hyprland.workspaces.values.filter(function(w) { return w.id > 0 })
  function workspacesOn(mon) {
    return workspaces.filter(function(w) { return w.monitor === mon }).sort(function(a, b) { return a.id - b.id })
  }
  function windowsOn(ws) { return ws && ws.toplevels ? ws.toplevels.values : [] }
  // live geometry comes from Hyprland's last answer; ask again while shown
  property int watchers: 0
  // re-read on Hyprland's events (and once in a while), not every second:
  // polling leaked memory in Quickshell's IPC objects
  Timer { interval: 5000; repeat: true; triggeredOnStart: true; running: wm.watchers > 0; onTriggered: Hyprland.refreshToplevels() }
  Connections { target: Hyprland; enabled: wm.watchers > 0; function onRawEvent(ev) { if (/^(openwindow|closewindow|movewindow|changefloatingmode|fullscreen|workspace)/.test(ev.name)) wsRefresh.restart() } }
  Timer { id: wsRefresh; interval: 200; onTriggered: Hyprland.refreshToplevels() }

  // names (and icons) per workspace id, from the settings
  readonly property var names: opt("names", ({}))
  function nameOf(ws) { return names[String(ws.id)] || "" }
  function setName(id, name) { var n = Object.assign({}, names); if (name) n[String(id)] = name; else delete n[String(id)]; persist({ names: n }) }

  // an app's icon from its window class
  function iconOf(tl) {
    var o = tl && tl.lastIpcObject ? tl.lastIpcObject : {}
    var cls = String(o["class"] || (tl && tl.wayland ? tl.wayland.appId : "") || "")
    var e = cls ? DesktopEntries.heuristicLookup(cls) : null
    return e && e.icon ? Quickshell.iconPath(e.icon, true) : (cls ? Quickshell.iconPath(cls.toLowerCase(), true) : "")
  }

  // ---------------------------------------------------------- actions
  function lua(cmd) { Hyprland.dispatch(cmd) }
  function goWorkspace(id) { lua('hl.dsp.focus({ workspace = "' + id + '" })') }
  function addr(tl) { var a = String(tl.address); return a.indexOf("0x") === 0 ? a : "0x" + a }
  function goWindow(tl) { lua('hl.dsp.focus({ window = "address:' + addr(tl) + '" })') }
  function moveWindow(tl, id) { lua('hl.dsp.window.move({ workspace = "' + id + '", window = "address:' + addr(tl) + '", follow = false })') }
  // picture-in-picture (after Hyprpin, jondkinney, MIT): float, a third of
  // the focused monitor's width, bottom right, on every workspace; again = back
  function pinWindow(tl) {
    var o = tl.lastIpcObject || {}, w = 'window = "address:' + addr(tl) + '"'
    if (o.pinned) {
      lua('hl.dsp.window.pin({ ' + w + ', action = "toggle" })')
      if (!(tl.monitor && monitorMode(tl.monitor) === "floating")) lua('hl.dsp.window.float({ ' + w + ', action = "disable" })')
      return
    }
    var m = Hyprland.focusedMonitor, sc = m.scale || 1, r = (m.lastIpcObject || {}).reserved || [0, 0, 0, 0]
    var W = Math.round(m.width / sc / 3), H = Math.round(W * 9 / 16), g = 20
    lua('hl.dsp.window.float({ ' + w + ', action = "enable" })')
    lua('hl.dsp.window.resize({ ' + w + ', x = ' + W + ', y = ' + H + ' })')
    lua('hl.dsp.window.move({ ' + w + ', x = ' + Math.round(m.x + m.width / sc - r[2] - W - g) + ', y = ' + Math.round(m.y + m.height / sc - r[3] - H - g) + ' })')
    lua('hl.dsp.window.pin({ ' + w + ', action = "toggle" })')
  }
  function closeWindow(tl) { lua('hl.dsp.window.close({ window = "address:' + addr(tl) + '" })') }
  // a new workspace: the first free number, on that monitor
  function newOn(mon) {
    var used = workspaces.map(function(w) { return w.id }), id = 1
    while (used.indexOf(id) >= 0) id++
    lua('hl.dsp.focus({ monitor = "' + mon.name + '" })')
    goWorkspace(id)
  }

  // tiling mode per workspace: a live rule now, and a block in
  // ~/.config/hypr/looknfeel.lua so it stays after a restart
  readonly property var layouts: opt("layouts", ({}))
  function layoutOf(id) { return layouts[String(id)] || "" }
  function setLayout(id, mode) {
    var l = Object.assign({}, layouts)
    if (mode) l[String(id)] = mode; else delete l[String(id)]
    persist({ layouts: l })
    lua('hl.workspace_rule({ workspace = "' + id + '", layout = "' + (mode || defaultLayout) + '" })')
    writeRules(l, monitorModes)
  }

  // a mode for a whole monitor: a tiling layout, or "floating" — tiling off:
  // every window there floats, new ones too (a named window rule)
  readonly property var monitorModes: opt("monitorModes", ({}))
  function monitorMode(mon) { return monitorModes[mon.name] || "" }
  function setMonitorMode(mon, mode) {
    var m = Object.assign({}, monitorModes), was = m[mon.name] || ""
    if (mode) m[mon.name] = mode; else delete m[mon.name]
    persist({ monitorModes: m })
    var sel = 'm[' + mon.name + ']'
    lua('hl.workspace_rule({ workspace = "' + sel + '", layout = "' + (mode && mode !== "floating" ? mode : defaultLayout) + '" })')
    lua('hl.window_rule({ name = "thenotch-float-' + mon.name + '", enabled = ' + (mode === "floating") + ', match = { workspace = "' + sel + '" }, float = true })')
    // the windows already there follow
    if (mode === "floating" || was === "floating") {
      var ws = workspacesOn(mon)
      for (var i = 0; i < ws.length; i++) {
        var tls = windowsOn(ws[i])
        for (var j = 0; j < tls.length; j++) lua('hl.dsp.window.float({ window = "address:' + addr(tls[j]) + '", action = "' + (mode === "floating" ? "enable" : "disable") + '" })')
      }
    }
    writeRules(layouts, m)
  }
  property string defaultLayout: "dwindle"
  Process {
    command: ["hyprctl", "getoption", "general:layout", "-j"]
    running: true
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: { try { wm.defaultLayout = JSON.parse(text).str || "dwindle" } catch (e) {} } }
  }
  readonly property string rulesFile: Quickshell.env("HOME") + "/.config/hypr/looknfeel.lua"
  // monitors first, then single workspaces (the later, narrower rule wins)
  function writeRules(l, mm) {
    var lines = []
    Object.keys(mm).forEach(function(n) {
      var sel = 'm[' + n + ']'
      if (mm[n] === "floating") lines.push('hl.window_rule({ name = "thenotch-float-' + n + '", match = { workspace = "' + sel + '" }, float = true })')
      else lines.push('hl.workspace_rule({ workspace = "' + sel + '", layout = "' + mm[n] + '" })')
    })
    Object.keys(l).forEach(function(id) { lines.push('hl.workspace_rule({ workspace = "' + id + '", layout = "' + l[id] + '" })') })
    var body = lines.join("\n")
    Quickshell.execDetached(["python3", "-I", "-c",
      "import re,sys\np,body=sys.argv[1],sys.argv[2]\ns=open(p).read()\n" +
      "s=re.sub(r'\\n?-- BEGIN thenotch-workspaces.*?-- END thenotch-workspaces\\n?','\\n',s,flags=re.S).rstrip('\\n')+'\\n'\n" +
      "if body: s+='\\n-- BEGIN thenotch-workspaces\\n-- Written by TheNotch (Settings → Workspaces). Edit there, or delete this block.\\n'+body+'\\n-- END thenotch-workspaces\\n'\n" +
      "open(p,'w').write(s)", rulesFile, body])
  }

  // the overview's key: a block in ~/.config/hypr/bindings.lua
  readonly property bool hotkey: opt("hotkey", true) !== false
  readonly property string bindFile: Quickshell.env("HOME") + "/.config/hypr/bindings.lua"
  function setHotkey(on) { persist({ hotkey: on }); writeBind(on) }
  function writeBind(on) {
    Quickshell.execDetached(["python3", "-I", "-c",
      "import re,sys\np,on=sys.argv[1],sys.argv[2]=='1'\ns=open(p).read()\n" +
      "new=re.sub(r'\\n?-- BEGIN thenotch-overview.*?-- END thenotch-overview\\n?','\\n',s,flags=re.S).rstrip('\\n')+'\\n'\n" +
      "if on: new+='\\n-- BEGIN thenotch-overview\\n-- Written by TheNotch (Settings → Workspaces). Edit there, or delete this block.\\n" +
      "o.bind(\"SUPER + grave\", \"Workspace overview\", \"omarchy-shell osia.thenotch overview\")\\n" +
      "o.bind(\"SUPER + SHIFT + mouse:272\", \"Move window into a snap zone\", hl.dsp.window.drag(), { mouse = true })\\n" +
      "o.bind(\"SUPER + SHIFT + mouse:272\", nil, \"omarchy-shell osia.thenotch snapStart\", { non_consuming = true })\\n" +
      "o.bind(\"SUPER + SHIFT + mouse:272\", nil, \"omarchy-shell osia.thenotch snapEnd\", { release = true, non_consuming = true })\\n-- END thenotch-overview\\n'\n" +
      "if new!=s: open(p,'w').write(new)", bindFile, on ? "1" : "0"])
  }
  Component.onCompleted: if (active) writeBind(hotkey)

  // ---------------------------------------------- snap zones (floating)
  // Super + Shift + left drag shows the monitor's zones; letting go puts the
  // window into the zone under the cursor. Layouts are shares of the
  // monitor's free area (the notch / bars left out), with a gap.
  readonly property var snapLayouts: ({
    halves:   [[0, 0, .5, 1], [.5, 0, .5, 1]],
    thirds:   [[0, 0, 1/3, 1], [1/3, 0, 1/3, 1], [2/3, 0, 1/3, 1]],
    quarters: [[0, 0, .5, .5], [.5, 0, .5, .5], [0, .5, .5, .5], [.5, .5, .5, .5]],
    main:     [[0, 0, .6, 1], [.6, 0, .4, .5], [.6, .5, .4, .5]],
    wide:     [[0, 0, .25, 1], [.25, 0, .5, 1], [.75, 0, .25, 1]]
  })
  readonly property var snapChoice: opt("snap", ({}))
  function snapLayoutOf(mon) {
    var c = snapChoice[mon.name]
    if (c && snapLayouts[c]) return c
    return mon.width / Math.max(1, mon.height) > 2 ? "wide" : "halves"     // ultrawide → three columns
  }
  function setSnapLayout(mon, id) { var c = Object.assign({}, snapChoice); c[mon.name] = id; persist({ snap: c }) }
  readonly property int snapGap: 10
  function zonesFor(mon) {
    var o = mon.lastIpcObject || {}, r = o.reserved || [0, 0, 0, 0], sc = mon.scale || 1
    var X = mon.x + r[0], Y = mon.y + r[1], W = mon.width / sc - r[0] - r[2], H = mon.height / sc - r[1] - r[3], g = snapGap
    return snapLayouts[snapLayoutOf(mon)].map(function(z) {
      return { x: Math.round(X + z[0] * W + g), y: Math.round(Y + z[1] * H + g), w: Math.round(z[2] * W - 2 * g), h: Math.round(z[3] * H - 2 * g) }
    })
  }
  property bool snapping: false
  property var snapZone: null                   // { mon, i, z }
  function snapStart() { Hyprland.refreshMonitors(); snapZone = null; snapping = true }
  function snapEnd() {
    var z = snapZone
    snapping = false; snapZone = null
    if (!z) return
    lua('hl.dsp.window.float({ action = "enable" })')
    lua('hl.dsp.window.resize({ x = ' + z.z.w + ', y = ' + z.z.h + ' })')
    lua('hl.dsp.window.move({ x = ' + z.z.x + ', y = ' + z.z.y + ' })')
  }
  // a release that never came (Shift let go first): the zones go anyway
  Timer { interval: 15000; running: wm.snapping; onTriggered: { wm.snapping = false; wm.snapZone = null } }
  // where the cursor is, while dragging
  Timer { interval: 60; repeat: true; running: wm.snapping; onTriggered: if (!cursor.running) cursor.running = true }
  Process {
    id: cursor
    command: ["hyprctl", "cursorpos", "-j"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var c = JSON.parse(text), hit = null
          for (var i = 0; i < wm.monitors.length && !hit; i++) {
            var zs = wm.zonesFor(wm.monitors[i])
            for (var j = 0; j < zs.length; j++) {
              var z = zs[j]
              if (c.x >= z.x - wm.snapGap && c.x <= z.x + z.w + wm.snapGap && c.y >= z.y - wm.snapGap && c.y <= z.y + z.h + wm.snapGap) { hit = { mon: wm.monitors[i].name, i: j, z: z }; break }
            }
          }
          wm.snapZone = hit
        } catch (e) {}
      }
    }
  }
  Variants {
    model: wm.active && wm.snapping ? wm.monitors : []
    delegate: SnapOverlay {
      required property var modelData
      mod: wm; hmon: modelData
      screen: Quickshell.screens.filter(function(s) { return s.name === modelData.name })[0] || null
    }
  }

  // ---------------------------------------------------- full-screen view
  property bool overview: false
  Variants {
    model: wm.active && wm.overview ? Quickshell.screens : []
    delegate: Overview { required property var modelData; screen: modelData; mod: wm }
  }
  onOverviewChanged: watchers += overview ? 1 : -1
}
