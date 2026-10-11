import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import qs.Commons
import "I18n.js" as I18n
import "modules/index.js" as Index

// TheNotch core. Owns the state everything else reads:
//   settings   ~/.config/thenotch/settings.json (core keys + modules.<id>)
//   modules    one object per dashboard (modules/index.js), created once
//   state      idle → live (a module has something going on) → peek (hover)
//              → expanded (clicked open); events flash over idle/live
//   events     flash({ key, icon | iconSource | art, title, message | progress,
//              ms, big, hold, action(), dismiss(), onHold(bool) })
//   window     one NotchWindow on the chosen monitor and edge
// While active it hides the Omarchy bar (`omarchy toggle bar on` sets the
// bar-off flag) and brings it back when it goes away.
Item {
  id: core

  property var shell: null
  property var manifest: null

  // ---------------------------------------------------------------- look
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color urgent: Color.urgent
  readonly property color islandColor: opt("look", "theme") === "black" ? "#000000" : Color.background
  readonly property string ff: Style.font.family
  readonly property string lang: String(opt("lang", "ru"))
  function t(key, args) { return I18n.t(lang, key, args) }

  // ------------------------------------------------------------ settings
  readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/thenotch"
  property var settings: ({})
  property bool settingsLoaded: false

  function opt(key, fallback) {
    var v = settings ? settings[key] : undefined
    return v === undefined || v === null ? fallback : v
  }
  function persist(values) {
    var s = {}
    for (var k in settings) s[k] = settings[k]
    for (var key in values) s[key] = values[key]
    settings = s
    store.setText(JSON.stringify(s, null, 2) + "\n")
  }
  function moduleOpt(id, key, fallback) {
    var m = settings && settings.modules ? settings.modules[id] : null
    var v = m ? m[key] : undefined
    return v === undefined || v === null ? fallback : v
  }
  function modulePersist(id, values) {
    var mods = {}
    var cur = settings && settings.modules ? settings.modules : {}
    for (var k in cur) mods[k] = cur[k]
    var m = {}
    var old = mods[id] || {}
    for (var a in old) m[a] = old[a]
    for (var b in values) m[b] = values[b]
    mods[id] = m
    persist({ modules: mods })
  }

  Process { id: mkdir; command: ["mkdir", "-p", core.configDir]; onExited: store.reload() }
  FileView {
    id: store
    path: core.configDir + "/settings.json"
    watchChanges: true
    printErrors: false
    onLoaded: {
      try { var s = JSON.parse(text()); if (s && typeof s === "object") core.settings = s } catch (e) {}
      core.settingsLoaded = true
    }
    onLoadFailed: core.settingsLoaded = true
    onFileChanged: reload()
  }
  Component.onCompleted: { mkdir.running = true; barStartup.start() }

  // ---------------------------------------------------------------- bar
  // TheNotch replaces the bar while it runs; the bar comes back when the
  // plugin is disabled or the option is turned off.
  readonly property bool hideBar: opt("hideBar", true) === true
  property bool barHidden: false
  function applyBar() {
    if (!settingsLoaded) return
    if (hideBar !== barHidden) {
      // the flag is "bar-off": "on" hides the bar, "off" shows it
      Quickshell.execDetached(["omarchy", "toggle", "bar", hideBar ? "on" : "off"])
      barHidden = hideBar
    }
  }
  onHideBarChanged: applyBar()
  // On a shell restart the old instance shows the bar on its way out, maybe
  // after we start: apply a moment later, and once more to be sure.
  // (settings can finish loading during construction, before any change
  // handler is connected, so this is driven by a timer from onCompleted)
  Timer {
    id: barStartup; interval: 1500; repeat: true
    onTriggered: {
      if (!core.settingsLoaded) return
      stop()
      core.barHidden = !core.hideBar
      core.applyBar()
      barConfirm.start()
    }
  }
  Timer {
    id: barConfirm; interval: 2500
    onTriggered: Quickshell.execDetached(["omarchy", "toggle", "bar", core.hideBar ? "on" : "off"])
  }
  Component.onDestruction: if (barHidden) Quickshell.execDetached(["omarchy", "toggle", "bar", "off"])

  // ------------------------------------------------------------ modules
  property var modules: []
  readonly property int moduleCount: modules.length
  function registerModule(m) {
    var list = modules.slice()
    list.push(m)
    list.sort(function(a, b) { return a.order - b.order })
    modules = list
  }
  function moduleById(id) {
    for (var i = 0; i < modules.length; i++) if (modules[i].moduleId === id) return modules[i]
    return null
  }
  Repeater {
    model: Index.MODULES
    delegate: Loader {
      required property var modelData
      required property int index
      source: Qt.resolvedUrl("modules/" + modelData.file)
      onLoaded: {
        item.notch = core
        item.moduleId = modelData.id
        item.order = index
        core.registerModule(item)
      }
    }
  }

  // the module whose live view the collapsed notch shows (highest priority)
  readonly property var liveModule: {
    var best = null
    for (var i = 0; i < modules.length; i++) {
      var m = modules[i]
      if (m.live && m.active && (!best || m.livePriority > best.livePriority)) best = m
    }
    return best
  }

  // ---------------------------------------------------- Omarchy plugins
  // for Settings → Plugins (and modules that defer to a plugin when it's on)
  property var omarchyPlugins: []
  property bool pluginsBusy: false
  function pluginEnabled(id) {
    for (var i = 0; i < omarchyPlugins.length; i++) if (omarchyPlugins[i].id === id) return omarchyPlugins[i].enabled === true
    return false
  }
  function refreshPlugins() { if (!pluginList.running) pluginList.running = true }
  function setPluginEnabled(id, on) {
    pluginsBusy = true
    pluginToggle.command = ["omarchy", "plugin", on ? "enable" : "disable", id]
    pluginToggle.running = true
  }
  Process {
    id: pluginList
    command: ["omarchy", "plugin", "list", "--json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: { try { core.omarchyPlugins = JSON.parse(text) } catch (e) {} }
    }
  }
  Process { id: pluginToggle; onExited: { core.pluginsBusy = false; core.refreshPlugins() } }
  // at start, then now and then: plugins also get switched outside the notch
  Timer { interval: 1200; running: true; onTriggered: core.refreshPlugins() }
  Timer { interval: 15000; running: true; repeat: true; onTriggered: core.refreshPlugins() }

  // -------------------------------------------------------------- state
  property string currentId: String(opt("module", "home"))
  readonly property var railModules: modules.filter(function(m) { return m.inRail && m.active })
  readonly property var tabModules: railModules.filter(function(m) { return m.topTab })
  readonly property var iconModules: railModules.filter(function(m) { return !m.topTab && !m.noIcon && m.page !== null })
  // the tab to go back to from a module opened by its icon
  property string lastTab: "home"
  readonly property var settingsModules: modules.filter(function(m) { return m.settingsPage !== null })
                                                .sort(function(a, b) { return a.sectionOrder - b.sectionOrder })
  readonly property var toggleModules: modules.filter(function(m) { return !m.core })
  readonly property var widgetModules: modules.filter(function(m) { return m.widgetPage !== null })
  function setModuleEnabled(id, on) { modulePersist(id, { enabled: on }) }
  readonly property var current: (function() { var m = moduleById(currentId); return m && m.inRail && m.page ? m : (tabModules.length ? tabModules[0] : railModules.length ? railModules[0] : null) })()

  // the settings window: sections from every module with a settingsPage
  property bool settingsOpen: false
  property string settingsSection: "settings"
  function openSettings(id) {
    var m = moduleById(id)
    settingsSection = m && m.settingsPage ? id : "settings"
    expanded = false; hovered = false
    settingsOpen = true
  }
  function openModule(id) {
    var m = moduleById(id)
    if (m && m.topTab) lastTab = id
    currentId = id; persist({ module: id }); expanded = true
  }

  property bool hovered: false
  property bool expanded: false
  property bool pointerInside: false
  readonly property bool peeking: hovered && !expanded && liveModule !== null && liveModule.peek !== null

  // what the island shows: expanded > event > peek > live > idle
  readonly property string mode: expanded ? "expanded"
    : currentEvent && (!hovered || currentEvent.hold) ? "event"
    : peeking ? "peek"
    : liveModule ? "live" : "idle"

  Timer { id: hoverTimer; interval: 260; onTriggered: core.hovered = true }
  Timer {
    id: leaveTimer
    interval: core.expanded ? 900 : 350
    onTriggered: { core.hovered = false; core.expanded = false }
  }
  // Has the pointer been on the notch since it opened? An open from IPC or a
  // key binding stays until the pointer has visited and left.
  property bool visited: false
  onExpandedChanged: visited = pointerInside
  function setPointerInside(inside) {
    pointerInside = inside
    if (inside) { visited = true; leaveTimer.stop(); hoverTimer.restart() }
    else { hoverTimer.stop(); if (!leaveTimer.running) leaveTimer.start() }
  }
  function toggleExpanded() { expanded = !expanded; if (!expanded) hovered = false }
  // clicks only open; leaving the notch is what closes it
  function expand() { if (!expanded) expanded = true }

  // -------------------------------------------------------------- events
  property var currentEvent: null
  property var eventQueue: []
  function flash(ev) {
    if (!ev) return
    // an event with a key replaces a queued/current one with the same key
    if (ev.key && currentEvent && currentEvent.key === ev.key) { currentEvent = ev; eventTimer.restart(); return }
    var q = eventQueue.filter(function(e) { return !ev.key || e.key !== ev.key })
    q.push(ev)
    eventQueue = q
    if (!currentEvent) nextEvent()
  }
  function nextEvent() {
    if (!eventQueue.length) { currentEvent = null; return }
    currentEvent = eventQueue[0]
    eventQueue = eventQueue.slice(1)
    eventTimer.interval = currentEvent.ms || 1800
    eventTimer.restart()
  }
  Timer { id: eventTimer; onTriggered: core.nextEvent() }
  // drop an event that went away at its source (e.g. a notification dismissed elsewhere)
  function removeEvent(key) {
    eventQueue = eventQueue.filter(function(e) { return e.key !== key })
    if (currentEvent && currentEvent.key === key) nextEvent()
  }
  // a "hold" event stays while the pointer is on it, then gets a short grace
  readonly property bool holding: hovered && currentEvent !== null && currentEvent.hold === true
  onHoldingChanged: {
    if (!currentEvent) return
    if (typeof currentEvent.onHold === "function") currentEvent.onHold(holding)
    if (holding) eventTimer.stop()
    else { eventTimer.interval = 2500; eventTimer.restart() }
  }
  function clickEvent() {
    var ev = currentEvent
    if (ev && typeof ev.action === "function") { ev.action(); removeEvent(ev.key) }
    else expand()
  }
  function dismissEvent() {
    var ev = currentEvent
    if (!ev) return
    if (typeof ev.dismiss === "function") ev.dismiss()
    removeEvent(ev.key)
  }

  // volume: the default output's level / mute, as a live event
  readonly property var sink: Pipewire.defaultAudioSink
  PwObjectTracker { objects: core.sink ? [core.sink] : [] }
  readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
  readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
  property bool settled: false
  Timer { interval: 2500; running: true; onTriggered: core.settled = true }
  onVolumeChanged: volumeEvent()
  onMutedChanged: volumeEvent()
  onSinkChanged: { settled = false; settleAgain.restart() }
  Timer { id: settleAgain; interval: 1500; onTriggered: core.settled = true }
  function volumeEvent() {
    if (!settled || opt("eventVolume", true) !== true || expanded) return
    flash({ key: "volume", icon: muted ? "󰝟" : volume > 0.6 ? "󰕾" : volume > 0.25 ? "󰖀" : "󰕿",
            title: muted ? t("muted") : t("volume"), progress: muted ? 0 : Math.min(1, volume), ms: 1400 })
  }

  // ---------------------------------------------------- desktop widgets
  // layout: { widgetId: { screenName: { x, y } } } in logical px from the
  // screen's top-left. A widget with no place yet lands on the notch's
  // monitor at its module's default spot.
  readonly property var deskModules: modules.filter(function(m) { return m.deskWidget !== null && m.active })
  // every desktop widget from the active modules: { wid, title, icon, component,
  // enabled, defaultPos, setEnabled(on) } — a module's main widget is keyed by
  // the module id, its extra ones (deskList) by their own wid
  readonly property var deskItems: {
    var out = []
    for (var i = 0; i < modules.length; i++) {
      var m = modules[i]
      if (!m.active) continue
      if (m.deskWidget !== null)
        out.push({ wid: m.moduleId, title: m.widgetTitle, icon: m.widgetIcon, component: m.deskWidget,
                   enabled: m.deskEnabled, defaultPos: m.deskDefault, setEnabled: m.setDeskEnabled, page: m.widgetPage })
      for (var j = 0; j < m.deskList.length; j++) (function(d) {
        out.push({ wid: d.wid, title: d.title, icon: d.icon, component: d.component, enabled: d.enabled,
                   defaultPos: d.defaultPos, setEnabled: function(on) { d.toggled(on) }, page: m.widgetPage })
      })(m.deskList[j])
    }
    return out
  }
  function deskItem(wid) { for (var i = 0; i < deskItems.length; i++) if (deskItems[i].wid === wid) return deskItems[i]; return null }
  readonly property var layout: opt("layout", ({}))
  function screenOf(name) {
    var l = Quickshell.screens
    for (var i = 0; i < l.length; i++) if (String(l[i].name) === name) return l[i]
    return null
  }
  function placesOf(id) {
    var p = layout[id], out = []
    if (p) for (var k in p) if (screenOf(k)) out.push(k)
    return out
  }
  function posOf(id, screen) {
    var p = layout[id] && layout[id][screen]
    if (p) return p
    var it = deskItem(id), sc = screenOf(screen)
    var d = it ? it.defaultPos : { x: 0.04, y: 0.08 }
    return sc ? { x: Math.round(sc.width * d.x), y: Math.round(sc.height * d.y) } : { x: 40, y: 40 }
  }
  // w, h: the widget's box when it was put there — so it can grow from the
  // right point later (see anchored)
  function setPos(id, screen, x, y, w, h) {
    var v = { x: Math.round(x), y: Math.round(y) }
    if (w > 0 && h > 0) { v.w = Math.round(w); v.h = Math.round(h) }
    patchPlace(id, screen, v)
  }
  // Auto-alignment: a widget keeps the side it was put against. Placed in the
  // left/middle/right third (top/middle/bottom), it grows from that edge or
  // from its centre — a long quote at the bottom centre grows upwards and
  // stays centred instead of spilling right and down.
  function anchored(p, bw, bh, sw, sh) {
    if (!sw || !sh) return { x: p.x, y: p.y }
    if (!p.w || !p.h)                                         // no saved size: just keep it on screen
      return { x: Math.round(Math.max(0, Math.min(sw - bw, p.x))), y: Math.round(Math.max(0, Math.min(sh - bh, p.y))) }
    var cx = (p.x + p.w / 2) / sw, cy = (p.y + p.h / 2) / sh
    var ax = cx < 0.38 ? 0 : cx > 0.62 ? 1 : 0.5, ay = cy < 0.38 ? 0 : cy > 0.62 ? 1 : 0.5
    var x = p.x + ax * (p.w - bw), y = p.y + ay * (p.h - bh)
    return { x: Math.round(Math.max(0, Math.min(sw - bw, x))), y: Math.round(Math.max(0, Math.min(sh - bh, y))) }
  }
  // Turned to about 90° or 270°, a widget that has a vertical layout uses it
  // (text stays upright) instead of being rotated as a picture; what's left
  // of the angle (within ±20°) still tilts it.
  function turnOf(rot, canVertical) {
    var r = ((rot % 360) + 360) % 360
    if (canVertical) {
      if (Math.abs(r - 90) <= 20) return { vertical: true, rot: r - 90 }
      if (Math.abs(r - 270) <= 20) return { vertical: true, rot: r - 270 }
    }
    return { vertical: false, rot: rot }
  }
  // rotation (degrees) and lock live next to the position
  function setRot(id, screen, deg) { patchPlace(id, screen, { rot: Math.round(deg) }) }
  function setLock(id, screen, on) { patchPlace(id, screen, { lock: on }) }
  function patchPlace(id, screen, values) {
    var l = JSON.parse(JSON.stringify(layout))
    if (!l[id]) l[id] = {}
    var cur = l[id][screen] || posOf(id, screen)
    for (var k in values) cur[k] = values[k]
    l[id][screen] = cur
    persist({ layout: l })
  }
  function setOnScreen(id, screen, on) {
    var l = JSON.parse(JSON.stringify(layout))
    if (on) { if (!l[id]) l[id] = {}; if (!l[id][screen]) l[id][screen] = posOf(id, screen) }
    else if (l[id]) delete l[id][screen]
    persist({ layout: l })
  }
  // every (widget, monitor) to draw: enabled widgets on their monitors
  readonly property var placements: {
    var out = []
    for (var i = 0; i < deskItems.length; i++) {
      var d = deskItems[i]
      if (!d.enabled) continue
      var screens = placesOf(d.wid)
      if (!screens.length) screens = [notchScreen]
      for (var j = 0; j < screens.length; j++) {
        var p = posOf(d.wid, screens[j])
        out.push(d.wid + "|" + screens[j] + "|" + p.x + "|" + p.y + "|" + (p.rot || 0) + "|" + (p.w || 0) + "|" + (p.h || 0) + "|" + (p.scale || 1))
      }
    }
    return out
  }
  property bool editingLayout: false
  function editLayout(on) { editingLayout = on; if (on) { expanded = false; settingsOpen = false } }
  Variants {
    model: core.editingLayout ? [] : core.placements
    delegate: WidgetWindow {
      required property var modelData
      readonly property var parts: String(modelData).split("|")
      notch: core
      desk: core.deskItem(parts[0])
      screen: core.screenOf(parts[1])
      posX: Number(parts[2]); posY: Number(parts[3]); rot: Number(parts[4])
      savedW: Number(parts[5]); savedH: Number(parts[6]); sc: Number(parts[7]) || 1
    }
  }
  Variants {
    model: core.editingLayout ? Quickshell.screens : []
    delegate: LayoutEditor {
      required property var modelData
      notch: core
      screen: modelData
    }
  }

  // -------------------------------------------------------------- window
  readonly property string edge: String(opt("edge", "top"))
  readonly property bool vertical: edge === "left" || edge === "right"
  readonly property string focusedScreen: Hyprland.focusedMonitor ? String(Hyprland.focusedMonitor.name || "") : ""
  // the notch stays on one monitor (Settings → General), it no longer follows focus
  readonly property string notchScreen: {
    var want = String(opt("screen", "")), list = Quickshell.screens
    for (var i = 0; i < list.length; i++) if (String(list[i].name) === want) return want
    return list.length ? String(list[0].name) : ""
  }
  function screenByName(name) {
    var list = Quickshell.screens
    for (var i = 0; i < list.length; i++) if (String(list[i].name) === name) return list[i]
    return list.length ? list[0] : null
  }
  // Layer-shell anchors don't re-apply on a live surface: a new monitor or
  // edge means a new window (Variants keyed by both).
  Variants {
    model: core.settingsOpen ? [core.focusedScreen] : []
    delegate: SettingsWindow {
      required property var modelData
      notch: core
      screen: core.screenByName(String(modelData))
    }
  }
  Variants {
    model: core.settingsLoaded ? [core.notchScreen + "|" + core.edge] : []
    delegate: NotchWindow {
      required property var modelData
      notch: core
      screen: core.screenByName(String(modelData).split("|")[0])
      edge: String(modelData).split("|")[1]
    }
  }

  // ----------------------------------------------------------------- IPC
  IpcHandler {
    target: "osia.thenotch"
    function toggle(): void { core.toggleExpanded() }
    function open(module: string): void { core.openModule(module || core.currentId) }
    function close(): void { core.expanded = false; core.hovered = false; core.settingsOpen = false }
    function edge(side: string): void { if (["top", "bottom", "left", "right"].indexOf(side) >= 0) core.persist({ edge: side }) }
    function cycleEdge(): void {
      var e = ["top", "right", "bottom", "left"]
      core.persist({ edge: e[(e.indexOf(core.edge) + 1) % 4] })
    }
    function bar(show: string): void { core.persist({ hideBar: show !== "on" && show !== "true" }) }
    function flash(json: string): void { try { core.flash(JSON.parse(json)) } catch (e) {} }
    function state(): string { return core.mode }
    function settings(section: string): void { core.openSettings(section || core.currentId) }
    function layout(): void { core.editLayout(!core.editingLayout) }
    // mute or unmute the default microphone (bind it to a key in Hyprland)
    function micMute(): void { var s = Pipewire.defaultAudioSource; if (s && s.audio) s.audio.muted = !s.audio.muted }
    function debug(): string { return JSON.stringify({ mode: core.mode, inside: core.pointerInside, visited: core.visited, hovered: core.hovered, leave: leaveTimer.running, loaded: core.settingsLoaded, hideBar: core.hideBar, barHidden: core.barHidden, startup: barStartup.running, ears: core.modules.filter(function(m) { return m.ear }).map(function(m) { return m.moduleId + "=" + m.ear }) }) }
  }
}
