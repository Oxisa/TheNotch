import QtQuick
import Quickshell.Services.Pipewire
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Commons
import "../.."
import "../../vendor/soundhub" as SH
import "../../vendor/soundhub/I18n.js" as HubI18n
import "../../DeskStyle.js" as DS
import "../../fonts"
import "../soundparts"

// SoundHub as a TheNotch dashboard. This object is the "host" the SoundHub
// pages expect (the bar panel plays the same role): colours, strings,
// settings, media, the shared cava capture, Focus sounds and the EQ backend.
// The pages come from vendor/soundhub; settings live in TheNotch's own file
// (modules.soundhub).
//   live   while a track plays: cover on one ear, spectrum on the other
//   peek   the compact player card
//   event  track changes
NotchModule {
  id: mod
  readonly property bool ru: notch !== null && notch.lang === "ru"
  title: ru ? "Звук" : "Sound"
  icon: "󰝚"
  description: ru ? "Сейчас играет, микшер, эквалайзер и фоновые звуки"
                  : "Now playing, mixer, equalizer and focus sounds"
  sectionOrder: 10
  settingsSection: "sound"
  noIcon: true                                  // no tab: Centre's sliders open it

  // ------------------------------------------------------- host: look
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property color urgent: Color.urgent
  readonly property string ff: Fonts.ui

  // --------------------------------------------------- host: settings
  function opt(key, fallback) { return notch ? notch.moduleOpt("soundhub", key, fallback) : fallback }
  function setting(key, fallback) { return opt(key, fallback) }        // MiniPlayer's name for it
  function persist(values) { if (notch) notch.modulePersist("soundhub", values) }
  readonly property string lang: notch ? notch.lang : "en"          // the shell's one language
  function t(key, args) { return HubI18n.t(lang, key, args) }

  // ------------------------------------------------------ host: media
  property var media: SH.Media {
    service: mod.notch && mod.notch.shell && typeof mod.notch.shell.serviceFor === "function"
             ? mod.notch.shell.serviceFor("omarchy.media") : null
  }
  readonly property var cava: SH.CavaHub
  property var ambient: SH.FocusState {}
  readonly property var player: media.activePlayer
  readonly property bool hasTrack: player !== null && !!(player.trackTitle || player.trackArtist)
  readonly property bool playing: hasTrack && !!player.isPlaying

  // --------------------------------------------- host: EQ backend + tabs
  readonly property string eqBin: decodeURIComponent(Qt.resolvedUrl("../../vendor/soundhub/bin/soundhub-eq").toString().replace(/^file:\/\//, ""))
  property var eq: ({ enabled: false, bands: [0, 0, 0, 0, 0, 0], autoPreamp: true, preamp: 0,
                      effectivePreamp: 0, preset: "flat", target: "" })
  property bool eqBusy: false
  property string eqError: ""
  property var eqQueue: []
  function eqRun(args) {
    if (eqProc.running) { eqQueue = eqQueue.concat([args]); return }
    eqBusy = true
    eqProc.command = [eqBin].concat(args)
    eqProc.running = true
  }
  Process {
    id: eqProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try { var r = JSON.parse(text); mod.eq = r; mod.eqError = r.ok ? "" : String(r.error || "") }
        catch (e) { mod.eqError = String(text).slice(0, 160) }
      }
    }
    onExited: {
      mod.eqBusy = false
      if (mod.eqQueue.length) { var n = mod.eqQueue[0]; mod.eqQueue = mod.eqQueue.slice(1); mod.eqRun(n) }
    }
  }
  function selectOutput(node) {
    if (!eq.enabled || !node) return false
    eqRun(["retarget", String(node.name)])
    return true
  }
  Component.onCompleted: eqRun(["status"])

  property int tab: 0
  property string eqScope: "global"
  // the mixer opens a mix's own EQ here, in the notch (tab 1 since the mixer moved to Settings)
  function openEqFor(mixId) { eqScope = mixId || "global"; tab = 1; if (notch) { notch.settingsOpen = false; notch.openModule("soundhub") } }
  property bool wide: false
  readonly property bool opened: notch !== null && notch.expanded && notch.current === mod

  // ------------------------------------------------------------- ambient
  // Your own tracks on a loop in the background (Sound → Ambient): files or
  // YouTube / YouTube Music links; they keep playing with the notch closed.
  readonly property QtObject amb: QtObject {
    readonly property var items: mod.opt("ambient", [])
    property bool playing: false
    readonly property real master: Number(mod.opt("ambientVolume", 0.8))
    function save(list) { mod.persist({ ambient: list }) }
    function toggle() { playing = !playing }
    function setMaster(v) { mod.persist({ ambientVolume: v }) }
    function update(id, v) { save(items.map(function(x) { return x.id === id ? Object.assign({}, x, v) : x })) }
    function remove(id) { save(items.filter(function(x) { return x.id !== id })) }
    function add(src, name) { var id = "a" + Date.now() + Math.floor(Math.random() * 1000); save(items.concat([{ id: id, src: src, name: name, volume: 0.6, on: true }])); return id }
    function addLink(url) { var id = add(url, url.replace(/^https?:\/\/(www\.)?/, "").slice(0, 50)); titleProc.ids = [id]; titleProc.command = ["yt-dlp", "--no-playlist", "--print", "title"].concat(mod.ambProxy ? ["--proxy", mod.ambProxy] : []).concat([url]); titleProc.running = true }
    function pickFiles() { if (!pickAudio.running) pickAudio.running = true }
    function stateOf(id) { for (var i = 0; i < tracks.count; i++) { var t = tracks.itemAt(i); if (t && t.item.id === id) return { error: t.error } } return {} }
  }
  Repeater {
    id: tracks
    model: mod.amb.items
    delegate: AmbientTrack { required property var modelData; item: modelData; master: mod.amb.master; playing: mod.amb.playing; proxy: mod.ambProxy }
  }
  // a local HTTP proxy (the tunnel app's), for links that don't resolve directly
  property string ambProxy: ""
  Process {
    running: true
    command: ["bash", "-c", "for p in 10809 2080 7890 8080; do curl -s -m 3 -o /dev/null -x http://127.0.0.1:$p http://www.gstatic.com/generate_204 && { echo http://127.0.0.1:$p; exit; }; done"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: mod.ambProxy = String(text).trim() }
  }
  Process {
    id: titleProc
    property var ids: []
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: { var t = String(text).trim(); if (t && titleProc.ids.length) mod.amb.update(titleProc.ids[0], { name: t }) } }
  }
  Process {
    id: pickAudio
    command: ["omarchy-file-select", "--title", mod.ru ? "Треки для эмбиента" : "Ambient tracks", "--multiple", "--extensions", "mp3 flac ogg opus wav m4a aac"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: String(text).trim().split("\n").filter(function(f) { return f }).forEach(function(f) { mod.amb.add(f, f.split("/").pop().replace(/\.[^.]+$/, "")) }) }
  }

  // tabs: 0 now playing, 1 EQ, 2 focus, 3 ambient, 4 microphone
  function tabName(k) { return k === "tab.ambient" ? (ru ? "Эмбиент" : "Ambient") : t(k) }
  pageWidth: tab === 0 ? (wide ? 840 : 400) : tab === 1 ? 500 : tab === 3 ? 560 : tab === 4 ? 520 : 440
  page: Component { SoundHubPage { host: mod } }
  // SoundHub's settings live in the settings window, not in a tab
  settingsPage: Component { SH.SettingsPage { host: mod; showDesk: false; showLang: false } }

  // ------------------------------------------- widget: now playing card
  // TheNotch draws it (settings in modules.soundhub) and tells the bar's
  // SoundHub to stand down through ~/.local/state/omarchy/thenotch-widgets.json.
  widgetTitle: ru ? "Сейчас играет" : "Now playing"
  widgetIcon: "󰍹"
  // a second widget: the big spectrum (visualizer), from the same cava capture
  // apps recording from a microphone right now: a mic next to the clock in
  // the collapsed notch (crossed out while the mic is muted)
  // a node's properties are only there while it is tracked
  readonly property var streamNodes: (Pipewire.nodes ? Pipewire.nodes.values : []).filter(function(n) { return n && n.isStream })
  PwObjectTracker { objects: mod.streamNodes }
  readonly property var micUsers: {
    var ns = streamNodes, out = []
    for (var i = 0; i < ns.length; i++) {
      var n = ns[i]
      if (!n || !n.isStream) continue
      var p = n.properties || {}, name = String(n.name || ""), app = String(p["application.name"] || "")
      if (String(p["media.class"] || "") !== "Stream/Input/Audio") continue
      if (/^(cava|quickshell|soundhub_|pw-record|pw-loopback)/i.test(name) || /^(quickshell|cava|PipeWire)$/i.test(app)) continue
      if (out.indexOf(app || name) < 0) out.push(app || name)
    }
    return out
  }
  readonly property var micSource: Pipewire.defaultAudioSource
  PwObjectTracker { objects: [mod.micSource] }
  // (who uses the mic shows as Privacy's dots in the notch)

  // a name a child's own `mod` property can't shadow
  readonly property var soundModule: mod
  readonly property bool vizOn: active && opt("vizWidget", false) === true
  onVizOnChanged: SH.CavaHub.want(cavaKey + "-viz", vizOn)
  deskList: [
    DeskWidget {
      wid: "visualizer"
      title: mod.ru ? "Визуализатор" : "Visualizer"
      icon: "\u{f0ea2}"
      component: Component { Visualizer { mod: soundModule } }
      enabled: mod.opt("vizWidget", false) === true
      defaultPos: ({ x: 0.40, y: 0.55 })
      onToggled: function(on) { mod.persist({ vizWidget: on }) }
    }
  ]

  // content for TheNotch's widget layer: the player card, shown while a track plays
  deskEnabled: opt("deskWidget", false) === true
  function setDeskEnabled(on) { persist({ deskWidget: on }) }
  deskDefault: ({ x: 0.02, y: 0.05 })
  deskWidget: Component {
    Loader {
      // card (default) or cassette
      property bool editing: false
      property bool deskVertical: false           // turned 90°: the card stands up (the cassette stays as it is)
      readonly property bool deskShown: item ? item.deskShown : false
      onEditingChanged: if (item) item.editing = editing
      onDeskVerticalChanged: if (item && "deskVertical" in item) item.deskVertical = deskVertical
      property var deskStyle: ({})
      onDeskStyleChanged: if (item && "deskStyle" in item) item.deskStyle = deskStyle
      onLoaded: { item.editing = editing; if ("deskVertical" in item) item.deskVertical = deskVertical; if ("deskStyle" in item) item.deskStyle = deskStyle }
      // no explicit size: the Loader takes its item's size (a set size would squeeze the item)
      sourceComponent: String(mod.opt("deskLook", "card")) === "cassette" ? cassetteLook : cardLook
    }
  }
  Component { id: cassetteLook; Cassette { host: soundModule } }
  Component {
    id: cardLook
    Rectangle {
      property bool editing: false
      property var deskStyle: ({})
      property bool deskVertical: false
      readonly property bool deskShown: mini.hasTrack || editing
      width: deskVertical ? vplayer.width + Style.space(28) : Style.space(400)
      height: deskVertical ? vplayer.implicitHeight + Style.space(28) : mini.implicitHeight + Style.space(28)
      VerticalPlayer {
        id: vplayer
        visible: parent.deskVertical && mini.hasTrack
        x: Style.space(14); y: Style.space(14)
        host: mod
      }
      radius: DS.radius(deskStyle, SH.HubStyle.radius + Style.space(4))
      topLeftRadius: DS.corner(deskStyle, "tl", SH.HubStyle.radius + Style.space(4))
      topRightRadius: DS.corner(deskStyle, "tr", SH.HubStyle.radius + Style.space(4))
      bottomLeftRadius: DS.corner(deskStyle, "bl", SH.HubStyle.radius + Style.space(4))
      bottomRightRadius: DS.corner(deskStyle, "br", SH.HubStyle.radius + Style.space(4))
      color: DS.bg(deskStyle, mod.bgc, mod.accent, Number(mod.opt("deskOpacity", 0.85)))
      border.width: 1
      border.color: DS.border(deskStyle, mod.fg)
      SH.MiniPlayer {
        id: mini
        ff: Fonts.desk
        opacity: hasTrack && !parent.deskVertical ? 1 : 0
        x: Style.space(14); y: Style.space(14)
        width: parent.width - Style.space(28)
        host: mod
      }
      Text {                                         // placeholder while arranging with nothing playing
        anchors.centerIn: parent
        visible: !mini.hasTrack
        text: "󰝚  " + (mod.ru ? "Сейчас играет" : "Now playing")
        color: Qt.darker(mod.fg, 1.4)
        font.family: mod.ff; font.pixelSize: Style.font.body
      }
    }
  }
  FileView { id: marker; path: Quickshell.env("HOME") + "/.local/state/omarchy/thenotch-widgets.json"; printErrors: false }
  function writeMarker() { marker.setText(JSON.stringify({ nowplaying: mod.active && mod.notch !== null })) }
  onActiveChanged: writeMarker()
  onNotchChanged: writeMarker()

  widgetPage: Component {
    Column {
      spacing: Style.space(10)
      readonly property bool visualizerPart: true
      SH.HubRow {
        title: mod.ru ? "Показывать на рабочем столе" : "Show on the desktop"
        hint: mod.ru ? "Карточка плеера под окнами, пока играет трек" : "A player card under the windows while a track plays"
        fg: mod.fg; fontFamily: mod.ff
        SH.HubSwitch {
          checked: mod.opt("deskWidget", false) === true
          fg: mod.fg; accent: mod.accent; ink: mod.bgc
          onToggled: mod.persist({ deskWidget: !checked })
        }
      }
      SH.HubRow {
        title: mod.ru ? "Вид" : "Look"; fg: mod.fg; fontFamily: mod.ff
        SH.HubSelect {
          width: Style.space(176); showLabel: false
          options: [{ value: "card", label: mod.ru ? "Карточка" : "Card" }, { value: "cassette", label: mod.ru ? "Кассета" : "Cassette" }]
          value: String(mod.opt("deskLook", "card"))
          foreground: mod.fg; accent: mod.accent; background: mod.bgc; fontFamily: mod.ff
          onChanged: function(v) { mod.persist({ deskLook: v }) }
        }
      }
      // the visualizer — Sound's second widget
      SH.HubCaption { text: mod.ru ? "Визуализатор" : "Visualizer"; icon: "\u{f0ea2}"; fg: mod.fg; fontFamily: mod.ff }
      SH.HubRow {
        title: mod.ru ? "Показывать на рабочем столе" : "Show on the desktop"
        hint: mod.ru ? "Большой спектр музыки от того же захвата звука" : "A big music spectrum from the same audio capture"
        fg: mod.fg; fontFamily: mod.ff
        SH.HubSwitch {
          checked: mod.opt("vizWidget", false) === true
          fg: mod.fg; accent: mod.accent; ink: mod.bgc
          onToggled: mod.persist({ vizWidget: !checked })
        }
      }
      SH.HubRow {
        title: mod.ru ? "Вид" : "Look"; fg: mod.fg; fontFamily: mod.ff
        SH.HubSelect {
          width: Style.space(176); showLabel: false
          options: [{ value: "bars", label: mod.ru ? "Столбики с пиками" : "Bars with peaks" },
                    { value: "led", label: mod.ru ? "LED-матрица" : "LED matrix" },
                    { value: "pulse", label: mod.ru ? "Круговой пульс" : "Pulse ring" }]
          value: String(mod.opt("vizLook", "bars"))
          foreground: mod.fg; accent: mod.accent; background: mod.bgc; fontFamily: mod.ff
          onChanged: function(v) { mod.persist({ vizLook: v }) }
        }
      }
    }
  }

  // ------------------------------------------------------------- live
  live: playing
  livePriority: 10
  readonly property string cavaKey: "notch-soundhub"
  onLiveChanged: SH.CavaHub.want(cavaKey, live)
  Component.onDestruction: {
    SH.CavaHub.want(cavaKey, false)
    SH.CavaHub.want(cavaKey + "-viz", false)
    marker.setText(JSON.stringify({ nowplaying: false }))     // let the bar's SoundHub draw it again
  }

  // iOS-style: a small rounded cover on the left, bars that dance to the
  // music on the right, tinted with the cover's own colour
  ColorQuantizer {
    id: artTone
    source: mod.player && mod.player.trackArtUrl ? mod.player.trackArtUrl : ""
    depth: 2
    rescaleSize: 48
  }
  readonly property color artColor: {
    var cs = artTone.colors, best = null, bs = -1
    for (var i = 0; i < cs.length; i++) { var c = cs[i], sc = c.hslSaturation * 0.7 + c.hslLightness * 0.3; if (c.hslLightness > 0.3 && sc > bs) { bs = sc; best = c } }
    return best ? Qt.hsla(best.hslHue, Math.max(best.hslSaturation, 0.45), Math.min(Math.max(best.hslLightness, 0.6), 0.75), 1) : mod.accent
  }
  liveLeft: Component {
    ClippingRectangle {
      width: Style.space(22); height: width
      radius: Style.space(6)
      color: SH.HubStyle.tint(mod.fg, 0.15)
      Image {
        anchors.fill: parent
        source: mod.player ? (mod.player.trackArtUrl || "") : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(64, 64)
      }
      Text {
        anchors.centerIn: parent
        visible: !(mod.player && mod.player.trackArtUrl)
        text: "\u{f075a}"; color: mod.artColor
        font.family: Fonts.ui; font.pixelSize: Style.font.caption
      }
    }
  }
  liveRight: Component {
    // six bars from the middle out; turned with a vertical notch
    Item {
      id: bars
      readonly property bool vert: mod.notch !== null && mod.notch.vertical
      width: vert ? Style.space(18) : Style.space(30)
      height: vert ? Style.space(30) : Style.space(18)
      readonly property var lv: mod.cava && mod.cava.levels ? mod.cava.levels : []
      Row {
        anchors.centerIn: parent
        rotation: bars.vert ? 90 : 0
        spacing: Style.space(2.5)
        Repeater {
          model: 6
          delegate: Rectangle {
            required property int index
            // pair cava's bands so the middle bars carry the bass
            readonly property real v: { var k = [4, 2, 0, 1, 3, 5][index]; var a = bars.lv[k * 2] || 0, b = bars.lv[k * 2 + 1] || 0; return mod.playing ? Math.max(a, b) : 0 }
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(3); radius: width / 2
            height: Math.max(Style.space(4), Style.space(18) * Math.min(1, 0.15 + v * 0.95))
            color: mod.artColor
            Behavior on height { NumberAnimation { duration: 90 } }
          }
        }
      }
    }
  }

  peek: Component { SH.MiniPlayer { host: mod } }
  peekWidth: 372

  // ------------------------------------------------------------ events
  readonly property string trackSig: player ? (player.trackTitle || "") + "\u0001" + (player.trackArtist || "") : ""
  property string lastTrack: ""
  onTrackSigChanged: {
    if (!trackSig || trackSig === lastTrack) return
    var first = lastTrack === ""
    lastTrack = trackSig
    if (first || !playing || !active || !notch || notch.opt("eventTrack", true) !== true) return
    notch.flash({ key: "track", art: player.trackArtUrl || "", icon: "󰝚",
                  title: player.trackTitle || "", message: player.trackArtist || "", ms: 2600 })
  }
}
