import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."
import "../../fonts"

// Recorder (Диктофон): record the microphone — or the microphone and the
// system's sound, for calls — keep the recordings and transcribe them on
// this machine with voxtype (whisper). bin/recorder does the work; the
// recordings are plain folders in ~/Recordings/Диктофон. After OmaRecorder
// (huey-holdings-llc/omarecorder, MIT) — the idea, not its code.
NotchModule {
  id: rm
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Диктофон", "Recorder")
  icon: "\u{f036c}"
  description: t("Запись голоса и созвонов, расшифровка в текст прямо на компьютере",
                 "Record your voice or calls and transcribe them on this machine")
  sectionOrder: 15
  pageWidth: 520
  page: Component { RecorderPage { mod: rm } }
  settingsPage: Component { RecorderSettings { mod: rm } }
  function opt(key, fallback) { return notch ? notch.moduleOpt("recorder", key, fallback) : fallback }
  function persist(values) { if (notch) notch.modulePersist("recorder", values) }

  readonly property string bin: decodeURIComponent(Qt.resolvedUrl("bin/recorder").toString().replace(/^file:\/\//, ""))
  property var st: ({ recording: null, jobs: {}, models: [], catalog: [] })
  property var items: []
  property var queue: []
  Process {
    id: proc
    property var args: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var d = JSON.parse(text)
          if (d.items) rm.items = d.items; else rm.st = d
          if (d.stopped) rm.stoppedNow(d.stopped)
        } catch (e) {}
        rm.next()
      }
    }
  }
  function next() {
    if (proc.running || !queue.length) return
    proc.command = [bin].concat(queue[0]); queue = queue.slice(1); proc.running = true
  }
  function cmd(args) { queue = queue.concat([args]); next() }
  function refresh() { cmd(["status"]); cmd(["list"]) }
  // while something happens (recording, transcribing, downloading) or the page is open
  readonly property bool busy: recording || Object.keys(st.jobs || {}).length > 0 || !!st.download
  Timer { interval: rm.busy ? 1500 : 6000; repeat: true; triggeredOnStart: true; running: rm.active && (rm.busy || (rm.notch !== null && rm.notch.expanded)); onTriggered: rm.refresh() }

  readonly property bool recording: !!st.recording
  readonly property bool withSystem: opt("system", false) === true
  readonly property string model: String(opt("model", "small"))
  readonly property string lang: String(opt("lang", "auto"))
  readonly property bool hasModel: (st.models || []).indexOf(model) >= 0
  function toggleRecording() { cmd(recording ? ["stop"] : ["start"].concat(withSystem ? ["--system"] : [])); cmd(["list"]) }
  function transcribe(id) { cmd(["transcribe", id, hasModel ? model : (st.models && st.models.length ? st.models[0] : model), lang]) }
  function stoppedNow(id) {
    if (opt("autoTranscribe", false) === true && hasModel) transcribe(id)
    if (notch) notch.flash({ key: "recorder", icon: "\u{f036c}", title: t("Запись сохранена", "Recording saved"), message: id, ms: 4000,
                             action: function() { notch.openModule("recorder") } })
  }

  property real nowMs: Date.now()
  Timer { interval: 1000; repeat: true; running: rm.recording; onTriggered: rm.nowMs = Date.now() }
  function fmt(sec) { sec = Math.max(0, Math.round(sec)); var m = Math.floor(sec / 60), s = sec % 60; return m + ":" + (s < 10 ? "0" : "") + s }
  readonly property string elapsed: recording ? fmt(nowMs / 1000 - st.recording.started) : ""

  // the collapsed notch: a red dot and the time while recording
  live: recording
  livePriority: 30
  liveLeft: Component {
    Rectangle {
      width: Style.space(10); height: width; radius: width / 2
      color: Color.urgent
      SequentialAnimation on opacity { loops: Animation.Infinite; running: true
        NumberAnimation { from: 1; to: 0.3; duration: 700 } NumberAnimation { from: 0.3; to: 1; duration: 700 } }
    }
  }
  liveRight: Component { Text { text: rm.elapsed; color: Color.foreground; font.family: Fonts.ui; font.pixelSize: Style.font.body; font.bold: true } }

}
