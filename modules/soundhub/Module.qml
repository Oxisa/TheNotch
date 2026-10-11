import QtQuick
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
  title: "SoundHub"
  icon: "󰝚"

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

  pageWidth: tab === 0 ? (wide ? 840 : 400) : tab === 1 ? 920 : tab === 2 ? 500 : 440
  page: Component { SoundHubPage { host: mod } }

  // ------------------------------------------------------------- live
  live: playing
  livePriority: 10
  readonly property string cavaKey: "notch-soundhub"
  onLiveChanged: SH.CavaHub.want(cavaKey, live)
  Component.onDestruction: SH.CavaHub.want(cavaKey, false)

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
    SH.Spectrum {
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

  peek: Component { SH.MiniPlayer { host: mod } }
  peekWidth: 372

  // ------------------------------------------------------------ events
  readonly property string trackSig: player ? (player.trackTitle || "") + "\u0001" + (player.trackArtist || "") : ""
  property string lastTrack: ""
  onTrackSigChanged: {
    if (!trackSig || trackSig === lastTrack) return
    var first = lastTrack === ""
    lastTrack = trackSig
    if (first || !playing || !notch || notch.opt("eventTrack", true) !== true) return
    notch.flash({ key: "track", art: player.trackArtUrl || "", icon: "󰝚",
                  title: player.trackTitle || "", message: player.trackArtist || "", ms: 2600 })
  }
}
