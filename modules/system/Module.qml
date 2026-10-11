import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."
import "../../../osia.soundhub" as SH
import "../agents"

// System: CPU, memory and GPU load as a desktop widget — one nested ring
// each (outer: load; inner: temperature, or video memory for the GPU), the
// same ring as Agents. Numbers come from bin/sysmon (/proc, /sys,
// nvidia-smi), which runs only while the widget is on. Idea from the
// telemetry rings of rover-001/whimsy (MIT); no code taken.
NotchModule {
  id: sm
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Система", "System")
  icon: "\u{f061a}"
  description: t("Загрузка процессора, памяти и видеокарты, температуры — виджетом на рабочем столе",
                 "CPU, memory and GPU load and temperatures as a desktop widget")
  topTab: true
  pageWidth: 720
  page: Component { SystemPage { mod: sm } }
  function opt(key, fallback) { return notch ? notch.moduleOpt("system", key, fallback) : fallback }
  function persist(values) { if (notch) notch.modulePersist("system", values) }

  // ---------------------------------------------------------- numbers
  property var data: ({})
  readonly property string bin: decodeURIComponent(Qt.resolvedUrl("bin/sysmon").toString().replace(/^file:\/\//, ""))
  Process {
    command: [sm.bin, "2"]
    running: sm.active && (sm.deskEnabled || (sm.notch !== null && sm.notch.expanded))
    stdout: SplitParser {
      onRead: function(line) {
        try { sm.data = JSON.parse(line) } catch (e) { return }
        var h = sm.netHistory.slice(-59); h.push({ down: sm.data.down || 0, up: sm.data.up || 0 }); sm.netHistory = h
      }
    }
  }
  property var netHistory: []                 // last 60 samples for the System tab
  function rate(b) {
    var ru_ = sm.ru
    if (b >= 2 ** 20) return (b / 2 ** 20).toFixed(1) + (ru_ ? " МБ/с" : " MB/s")
    if (b >= 1024) return Math.round(b / 1024) + (ru_ ? " КБ/с" : " KB/s")
    return Math.round(b) + (ru_ ? " Б/с" : " B/s")
  }
  function uptimeText(sec) {
    var d = Math.floor(sec / 86400), h = Math.floor(sec % 86400 / 3600), m = Math.floor(sec % 3600 / 60)
    return (d ? d + t(" д ", "d ") : "") + h + t(" ч ", "h ") + m + t(" мин", "m")
  }
  function gb(b) { return (b / 2 ** 30).toFixed(b >= 10 * 2 ** 30 ? 0 : 1) }
  readonly property var shownMetrics: opt("metrics", ["cpu", "ram", "gpu"])
  readonly property var rings: {
    var d = data, out = []
    if (shownMetrics.indexOf("cpu") >= 0 && d.cpu !== undefined)
      out.push({ id: "cpu", name: t("Процессор", "CPU"), sub: d.cpuTemp ? d.cpuTemp + "°C" : "",
                 limits: [{ label: t("Загрузка", "Load"), percent: d.cpu / 100, reset: "" }]
                         .concat(d.cpuTemp ? [{ label: t("Температура", "Temperature"), percent: d.cpuTemp / 100, reset: d.cpuTemp + "°C" }] : []) })
    if (shownMetrics.indexOf("ram") >= 0 && d.ramTotal)
      out.push({ id: "ram", name: t("Память", "Memory"), sub: gb(d.ramUsed) + " / " + gb(d.ramTotal) + t(" ГБ", " GB"),
                 limits: [{ label: t("Занято", "Used"), percent: d.ramUsed / d.ramTotal, reset: "" }] })
    if (shownMetrics.indexOf("gpu") >= 0 && d.gpu !== undefined)
      out.push({ id: "gpu", name: t("Видеокарта", "GPU"), sub: d.gpuTemp ? Math.round(d.gpuTemp) + "°C" : "",
                 limits: [{ label: t("Загрузка", "Load"), percent: d.gpu / 100, reset: "" }]
                         .concat(d.vramTotal ? [{ label: t("Видеопамять", "Video memory"), percent: d.vramUsed / d.vramTotal,
                                                  reset: gb(d.vramUsed) + " / " + gb(d.vramTotal) + t(" ГБ", " GB") }] : []) })
    if (shownMetrics.indexOf("disk") >= 0 && d.disks && d.disks.length)
      out.push({ id: "disk", name: t("Диск", "Disk"), sub: gb(d.disks[0].used) + " / " + gb(d.disks[0].total) + t(" ГБ", " GB"),
                 limits: [{ label: d.disks[0].mount, percent: d.disks[0].used / d.disks[0].total, reset: "" }] })
    return out
  }

  // ----------------------------------------------------------- widget
  widgetTitle: t("Система", "System")
  widgetIcon: "\u{f061a}"
  deskEnabled: opt("widget", false) === true
  function setDeskEnabled(on) { persist({ widget: on }) }
  deskDefault: ({ x: 0.02, y: 0.40 })
  deskWidget: Component {
    Rectangle {
      id: card
      property bool editing: false
      readonly property bool deskShown: true
      property bool deskVertical: false            // turned 90°: rings in a column
      width: Math.max(row.implicitWidth, netLine.visible ? netLine.implicitWidth : 0) + Style.space(32)
      height: row.implicitHeight + (netLine.visible ? netLine.implicitHeight + Style.space(8) : 0) + Style.space(28)
      radius: SH.HubStyle.radius + Style.space(4)
      readonly property color bg: Color.background
      color: Qt.rgba(bg.r, bg.g, bg.b, Number(sm.opt("opacity", 0.85)))
      border.width: 1
      border.color: SH.HubStyle.tint(Color.foreground, 0.08)
      Grid {
        id: row
        anchors.horizontalCenter: parent.horizontalCenter
        y: Style.space(14)
        columns: card.deskVertical ? 1 : 99
        spacing: Style.space(22)
        Repeater {
          model: sm.rings.length ? sm.rings : [{ name: sm.t("Система", "System"), limits: [], sub: "…" }]
          delegate: RingPair {
            required property var modelData
            agentData: modelData
            sub: modelData.sub || ""
            ru: sm.ru
            size: Style.space(60)
          }
        }
      }
      Text {
        id: netLine
        visible: sm.shownMetrics.indexOf("net") >= 0 && sm.data.down !== undefined
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: Style.space(12)
        text: card.deskVertical ? "\u{f0045} " + sm.rate(sm.data.down || 0) + "\n\u{f005d} " + sm.rate(sm.data.up || 0)
                                : "\u{f0045} " + sm.rate(sm.data.down || 0) + "    \u{f005d} " + sm.rate(sm.data.up || 0)
        horizontalAlignment: Text.AlignHCenter
        color: Qt.darker(Color.foreground, 1.2)
        font.family: Style.font.family; font.pixelSize: Style.font.caption
      }
    }
  }
  widgetPage: Component {
    Column {
      spacing: Style.space(10)
      SH.HubRow {
        title: sm.t("Показывать на рабочем столе", "Show on the desktop")
        hint: sm.t("Кольца: снаружи загрузка, внутри температура (у видеокарты — видеопамять)",
                   "Rings: load outside, temperature inside (video memory for the GPU)")
        fg: Color.foreground; fontFamily: Style.font.family
        SH.HubSwitch {
          checked: sm.deskEnabled
          fg: Color.foreground; accent: Color.accent; ink: Color.background
          onToggled: sm.setDeskEnabled(!checked)
        }
      }
      Flow {
        width: parent.width
        spacing: Style.space(6)
        Repeater {
          model: [{ id: "cpu", label: sm.t("Процессор", "CPU") }, { id: "ram", label: sm.t("Память", "Memory") },
                  { id: "gpu", label: sm.t("Видеокарта", "GPU") },
                  { id: "disk", label: sm.t("Диск", "Disk") }, { id: "net", label: sm.t("Сеть", "Network") }]
          delegate: SH.HubChip {
            required property var modelData
            readonly property bool on_: sm.shownMetrics.indexOf(modelData.id) >= 0
            icon: on_ ? "󰄬" : "󰅖"
            label: modelData.label
            on: on_
            subtle: true
            h: Style.space(26)
            fg: Color.foreground; accent: Color.accent; fontFamily: Style.font.family
            onClicked: {
              var m = sm.shownMetrics.slice()
              if (on_) m = m.filter(function(x) { return x !== modelData.id }); else m.push(modelData.id)
              sm.persist({ metrics: m })
            }
          }
        }
      }
      SH.HubRow {
        title: sm.t("Фон", "Background"); fg: Color.foreground; fontFamily: Style.font.family
        SH.HubSlider {
          width: Style.space(176)
          minimum: 0.2; maximum: 1; step: 0.05
          value: Number(sm.opt("opacity", 0.85))
          fillColor: Color.accent; fontFamily: Style.font.family
          onReleased: function(v) { sm.persist({ opacity: Math.round(v * 100) / 100 }) }
        }
      }
    }
  }
}
