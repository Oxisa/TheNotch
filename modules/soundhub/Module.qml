import QtQuick
import Quickshell.Services.Pipewire
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Commons
import "../.."
import "../../../osia.soundhub" as SH
import "../../../osia.soundhub/I18n.js" as HubI18n

// SoundHub as a TheNotch dashboard. This object is the "host" the SoundHub
// pages expect (the bar panel plays the same role): colours, strings,
// settings, media, the shared cava capture, Focus sounds and the EQ backend.
// The pages themselves are loaded from the osia.soundhub folder, so there is
// one copy of the UI; settings live in TheNotch's own file (modules.soundhub),
// seeded once from the bar widget's settings.
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
  topTab: true

  // ------------------------------------------------------- host: look
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property color urgent: Color.urgent
  readonly property string ff: Style.font.family

  // --------------------------------------------------- host: settings
  function opt(key, fallback) { return notch ? notch.moduleOpt("soundhub", key, fallback) : fallback }
  function setting(key, fallback) { return opt(key, fallback) }        // MiniPlayer's name for it
  function persist(values) { if (notch) notch.modulePersist("soundhub", values) }
  readonly property string lang: String(opt("lang", "en") || "en")
  function t(key, args) { return HubI18n.t(lang, key, args) }

  // First run: start from the bar widget's SoundHub settings.
  FileView {
    id: shellJson
    path: Quickshell.env("HOME") + "/.config/omarchy/shell.json"
    printErrors: false
    blockLoading: true
  }
  readonly property bool canSeed: notch !== null && notch.settingsLoaded
  onCanSeedChanged: seed()
  function seed() {
    if (!canSeed || (notch.settings.modules && notch.settings.modules.soundhub)) return
    var entry = {}
    try {
      var cfg = JSON.parse(shellJson.text())
      var secs = cfg.bar && cfg.bar.layout ? cfg.bar.layout : {}
      for (var s in secs) for (var i = 0; i < secs[s].length; i++)
        if (secs[s][i] && secs[s][i].id === "osia.soundhub") entry = secs[s][i]
    } catch (e) {}
    var v = {}
    for (var k in entry) if (k !== "id") v[k] = entry[k]
    v.seeded = true
    persist(v)
  }

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
  readonly property string eqBin: decodeURIComponent(Qt.resolvedUrl("../../../osia.soundhub/bin/soundhub-eq").toString().replace(/^file:\/\//, ""))
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
  function openEqFor(mixId) { eqScope = mixId || "global"; tab = 2 }
  property bool wide: false
  readonly property bool opened: notch !== null && notch.expanded && notch.current === mod

  pageWidth: tab === 0 ? (wide ? 840 : 400) : tab === 1 ? 920 : tab === 2 ? 500 : tab === 4 ? 520 : 440
  page: Component { SoundHubPage { host: mod } }
  // SoundHub's settings live in the settings window, not in a tab
  settingsPage: Component { SH.SettingsPage { host: mod; showDesk: false } }

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
  ear: active && opt("micIndicator", true) !== false && micUsers.length
       ? (micSource && micSource.audio && micSource.audio.muted ? "\u{f036d}" : "\u{f036c}") : ""

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
      onLoaded: { item.editing = editing; if ("deskVertical" in item) item.deskVertical = deskVertical }
      // no explicit size: the Loader takes its item's size (a set size would squeeze the item)
      sourceComponent: String(mod.opt("deskLook", "card")) === "cassette" ? cassetteLook : cardLook
    }
  }
  Component { id: cassetteLook; Cassette { host: soundModule } }
  Component {
    id: cardLook
    Rectangle {
      property bool editing: false
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
      radius: SH.HubStyle.radius + Style.space(4)
      color: Qt.rgba(mod.bgc.r, mod.bgc.g, mod.bgc.b, Number(mod.opt("deskOpacity", 0.85)))
      border.width: 1
      border.color: SH.HubStyle.tint(mod.fg, 0.08)
      SH.MiniPlayer {
        id: mini
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
      SH.HubRow {
        title: mod.ru ? "Фон" : "Background"; fg: mod.fg; fontFamily: mod.ff
        SH.HubSlider {
          width: Style.space(176)
          minimum: 0.2; maximum: 1; step: 0.05
          value: Number(mod.opt("deskOpacity", 0.85))
          fillColor: mod.accent; fontFamily: mod.ff
          onReleased: function(v) { mod.persist({ deskOpacity: Math.round(v * 100) / 100 }) }
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
      SH.HubRow {
        title: mod.ru ? "Фон визуализатора" : "Visualizer background"; fg: mod.fg; fontFamily: mod.ff
        SH.HubSlider {
          width: Style.space(176)
          minimum: 0; maximum: 1; step: 0.05
          value: Number(mod.opt("vizOpacity", 0.6))
          fillColor: mod.accent; fontFamily: mod.ff
          onReleased: function(v) { mod.persist({ vizOpacity: Math.round(v * 100) / 100 }) }
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

  liveLeft: Component {
    ClippingRectangle {
      width: Style.space(24); height: width
      radius: width / 2
      color: SH.HubStyle.tint(mod.fg, 0.15)
      Image {
        anchors.fill: parent
        source: mod.player ? (mod.player.trackArtUrl || "") : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(64, 64)
      }
      RotationAnimator on rotation {
        from: 0; to: 360; duration: 8000; loops: Animation.Infinite
        running: mod.playing
      }
    }
  }
  liveRight: Component {
    // on a left/right edge the notch is vertical: turn the spectrum with it
    Item {
      readonly property bool vert: mod.notch !== null && mod.notch.vertical
      width: vert ? Style.space(18) : Style.space(44)
      height: vert ? Style.space(44) : Style.space(18)
      SH.Spectrum {
      anchors.centerIn: parent
      rotation: parent.vert ? (mod.notch.edge === "left" ? 90 : -90) : 0
      width: Style.space(44); height: Style.space(18)
      levels: mod.cava && mod.cava.levels ? mod.cava.levels.slice(0, 10) : []
      style: "bars"
      mode: "mirror"
      accent: mod.accent
      color: mod.accent
      fg: mod.fg
      gap: 2
      minLevel: 0.08
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
