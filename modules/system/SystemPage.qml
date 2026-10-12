import QtQuick
import Quickshell.Io
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// System tab: three big rings (GPU, CPU, memory: load and temperature or
// video memory), then the network with a short history, the disks and how
// long the machine has been up, and the task manager (TaskManager).
Column {
  id: page
  property var mod: null
  spacing: Style.space(10)
  readonly property var d: mod ? mod.data : ({})
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }

  component Card: Rectangle {
    radius: SH.HubStyle.radius + Style.space(2)
    color: SH.HubStyle.tint(page.fg, 0.05)
    border.width: 1
    border.color: SH.HubStyle.tint(page.fg, 0.06)
  }

  property string host: ""
  Process {
    running: true
    command: ["bash", "-c", "echo \"$(hostname) · Linux $(uname -r | cut -d- -f1) · $(hyprctl version -j 2>/dev/null | jq -r '\"Hyprland \" + .tag' 2>/dev/null)\""]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: page.host = text.trim() }
  }

  Card {
    width: parent.width
    height: rings.implicitHeight + Style.space(24)
    Row {
      id: rings
      anchors.centerIn: parent
      spacing: Style.space(28)
      BigRing {
        visible: page.d.gpu !== undefined
        value: (page.d.gpuTemp || 0) / 100
        value2: (page.d.gpu || 0) / 100
        big: page.d.gpuTemp ? Math.round(page.d.gpuTemp) + "°C" : "—"
        label: page.t("Видеокарта", "GPU")
        small: page.t("загрузка ", "load ") + Math.round(page.d.gpu || 0) + "%"
      }
      BigRing {
        size: Style.space(190)
        value: (page.d.cpuTemp || 0) / 100
        value2: (page.d.cpu || 0) / 100
        big: page.d.cpuTemp ? page.d.cpuTemp + "°C" : "—"
        label: page.t("Процессор", "CPU")
        small: page.t("загрузка ", "load ") + Math.round(page.d.cpu || 0) + "%"
      }
      BigRing {
        value: page.d.ramTotal ? page.d.ramUsed / page.d.ramTotal : 0
        value2: page.d.vramTotal ? page.d.vramUsed / page.d.vramTotal : -1
        big: page.d.ramTotal ? page.mod.gb(page.d.ramUsed) + page.t(" ГБ", " GB") : "—"
        label: page.t("Память", "Memory")
        small: page.d.vramTotal ? page.t("видео ", "video ") + page.mod.gb(page.d.vramUsed) + page.t(" ГБ", " GB") : ""
      }
    }
  }

  Row {
    spacing: Style.space(10)
    // network
    Card {
      width: (page.width - Style.space(10)) / 2
      height: Style.space(120)
      Column {
        x: Style.space(14); y: Style.space(12)
        width: parent.width - Style.space(28)
        spacing: Style.space(6)
        Row {
          spacing: Style.space(18)
          Text { text: "\u{f0045} " + page.mod.rate(page.d.down || 0); color: page.accent; font.family: page.ff; font.pixelSize: Style.font.body; font.bold: true }
          Text { text: "\u{f005d} " + page.mod.rate(page.d.up || 0); color: page.fg; font.family: page.ff; font.pixelSize: Style.font.body; font.bold: true }
        }
        Canvas {
          id: spark
          width: parent.width; height: Style.space(60)
          Connections { target: page.mod; function onNetHistoryChanged() { spark.requestPaint() } }
          onPaint: {
            var ctx = getContext("2d"); ctx.reset()
            var h = page.mod ? page.mod.netHistory : [], n = h.length
            if (n < 2) return
            var mx = 1
            for (var i = 0; i < n; i++) mx = Math.max(mx, h[i].down, h[i].up)
            function line(key, col, fill) {
              ctx.beginPath()
              for (var i = 0; i < n; i++) {
                var x = i / (60 - 1) * width, y = height - h[i][key] / mx * (height - 2)
                if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
              }
              ctx.strokeStyle = col; ctx.lineWidth = 2; ctx.stroke()
              if (fill) { ctx.lineTo((n - 1) / 59 * width, height); ctx.lineTo(0, height); ctx.closePath(); ctx.fillStyle = Qt.rgba(page.accent.r, page.accent.g, page.accent.b, 0.15); ctx.fill() }
            }
            line("down", page.accent, true)
            line("up", Qt.rgba(page.fg.r, page.fg.g, page.fg.b, 0.6), false)
          }
        }
      }
    }
    // disks and uptime
    Card {
      width: (page.width - Style.space(10)) / 2
      height: Style.space(120)
      Column {
        x: Style.space(14); y: Style.space(12)
        width: parent.width - Style.space(28)
        spacing: Style.space(8)
        Repeater {
          model: (page.d.disks || []).slice(0, 2)
          delegate: Column {
            required property var modelData
            width: parent.width
            spacing: Style.space(3)
            Item {
              width: parent.width; height: dl.implicitHeight
              Text { id: dl; text: "\u{f02ca} " + modelData.mount; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption; font.bold: true }
              Text { anchors.right: parent.right; text: page.mod.gb(modelData.used) + " / " + page.mod.gb(modelData.total) + page.t(" ГБ", " GB"); color: Qt.darker(page.fg, 1.4); font.family: page.ff; font.pixelSize: Style.font.caption - 1 }
            }
            Rectangle {
              width: parent.width; height: Style.space(6); radius: height / 2
              color: SH.HubStyle.tint(page.fg, 0.1)
              Rectangle { width: parent.width * modelData.used / modelData.total; height: parent.height; radius: height / 2; color: page.accent }
            }
          }
        }
        Text {
          text: "\u{f0954} " + page.t("Работает ", "Up ") + page.mod.uptimeText(page.d.uptime || 0)
          color: Qt.darker(page.fg, 1.3)
          font.family: page.ff; font.pixelSize: Style.font.caption
        }
        Text {
          width: parent.width; elide: Text.ElideRight
          text: page.host
          color: Qt.darker(page.fg, 1.6)
          font.family: page.ff; font.pixelSize: Style.font.caption - 1
        }
      }
    }
  }

  TaskManager { width: parent.width; mod: page.mod }
}
