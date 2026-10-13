import QtQuick
import Quickshell
import Quickshell.Io

// One ambient track on a loop, played by mpv: a file, an audio link, or a
// YouTube / YouTube Music page (mpv asks yt-dlp). When a local HTTP proxy is
// up (the tunnel app's), links go through it — some sites don't resolve
// otherwise. Volume changes go to mpv's IPC socket, no restart.
Item {
  id: tr
  property var item: ({})                       // { id, name, src, volume, on }
  property real master: 1
  property bool playing: false
  property string proxy: ""
  property string error: ""
  readonly property bool want: playing && item.on !== false && !!item.src
  readonly property int vol: Math.round(100 * Math.max(0, Math.min(1, Number(item.volume !== undefined ? item.volume : 0.6) * master)))
  readonly property string sock: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/thenotch-ambient-" + item.id + ".sock"
  readonly property bool link: /^https?:\/\//.test(String(item.src || ""))

  Process {
    id: mpv
    running: tr.want
    command: ["mpv", "--no-video", "--no-terminal", "--loop-file=inf", "--loop-playlist=inf", "--volume=" + tr.vol,
              "--input-ipc-server=" + tr.sock, "--title=thenotch-ambient"]
             .concat(tr.link && tr.proxy ? ["--http-proxy=" + tr.proxy, "--ytdl-raw-options=proxy=" + tr.proxy] : [])
             .concat(["--", String(tr.item.src || "")])
    stderr: StdioCollector { waitForEnd: true; onStreamFinished: { var e = String(text).trim().split("\n").filter(function(l) { return /error|fail/i.test(l) }).pop(); if (e) tr.error = e.slice(0, 120) } }
    onRunningChanged: if (running) tr.error = ""
  }
  onVolChanged: if (mpv.running) Quickshell.execDetached(["bash", "-c", "printf '{\"command\":[\"set_property\",\"volume\",%s]}\\n' \"$1\" | socat - \"$2\" >/dev/null 2>&1", "--", String(vol), sock])
}
