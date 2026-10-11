import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."
import "../../../osia.omaloader" as OL
import "../../../osia.soundhub" as SH

// Omaloader as a TheNotch dashboard: the same engine and UI as the bar
// plugin (loaded from the osia.omaloader folder), with settings in TheNotch's
// file (modules.omaloader), seeded once from the bar widget's settings.
//   live   while downloading: download glyph · percent (above music)
//   peek   what's downloading, progress, cancel
// "Done" needs no event of its own: Omaloader's notification shows in the
// notch through the notifications module.
NotchModule {
  id: omod
  title: notch && notch.lang === "ru" ? "Загрузки" : "Downloads"
  icon: "󰇚"
  description: notch && notch.lang === "ru" ? "Скачивание видео, звука и GIF по ссылке" : "Download video, audio and GIFs from a link"
  sectionOrder: 11
  pageWidth: 400
  page: Component { OL.Content { host: omod.engine; only: "download" } }
  settingsPage: Component { OL.Content { host: omod.engine; only: "settings" } }

  property var engine: OL.Engine {
    settings: omod.notch && omod.notch.settings.modules && omod.notch.settings.modules.omaloader
              ? omod.notch.settings.modules.omaloader : ({})
    onPersistRequested: function(values) { if (omod.notch) omod.notch.modulePersist("omaloader", values) }
  }

  // first run: start from the bar widget's settings
  FileView {
    id: shellJson
    path: Quickshell.env("HOME") + "/.config/omarchy/shell.json"
    printErrors: false
    blockLoading: true
  }
  readonly property bool canSeed: notch !== null && notch.settingsLoaded
  onCanSeedChanged: {
    if (!canSeed || (notch.settings.modules && notch.settings.modules.omaloader)) return
    var entry = {}
    try {
      var cfg = JSON.parse(shellJson.text())
      var secs = cfg.bar && cfg.bar.layout ? cfg.bar.layout : {}
      for (var s in secs) for (var i = 0; i < secs[s].length; i++)
        if (secs[s][i] && secs[s][i].id === "osia.omaloader") entry = secs[s][i]
    } catch (e) {}
    var v = {}
    for (var k in entry) if (k !== "id") v[k] = entry[k]
    v.seeded = true
    notch.modulePersist("omaloader", v)
  }

  // ------------------------------------------------------------- live
  live: engine.running
  livePriority: 20
  readonly property string pct: engine.indeterminate ? "…" : Math.round(engine.progress) + "%"

  liveLeft: Component {
    Text {
      text: "󰇚"
      color: Color.accent
      font.family: Style.font.family; font.pixelSize: Style.font.body + 2
      SequentialAnimation on opacity {
        running: omod.engine.running; loops: Animation.Infinite
        NumberAnimation { from: 1; to: 0.35; duration: 650; easing.type: Easing.InOutQuad }
        NumberAnimation { from: 0.35; to: 1; duration: 650; easing.type: Easing.InOutQuad }
      }
    }
  }
  liveRight: Component {
    Text {
      text: omod.pct
      color: Color.foreground
      font.family: Style.font.family; font.pixelSize: Style.font.caption; font.bold: true
    }
  }

  peekWidth: 360
  peek: Component {
    Column {
      spacing: Style.space(8)
      Row {
        width: parent.width
        spacing: Style.space(10)
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "󰇚"
          color: Color.accent
          font.family: Style.font.family; font.pixelSize: Style.space(22)
        }
        Column {
          width: parent.width - Style.space(32) - cancel.width - parent.spacing * 2
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(2)
          Text {
            width: parent.width
            text: omod.engine.previewTitle || omod.engine.url
            color: Color.foreground
            font.family: Style.font.family; font.pixelSize: Style.font.body; font.bold: true
            elide: Text.ElideRight
          }
          Text {
            width: parent.width
            text: omod.engine.statusText
            color: Qt.darker(Color.foreground, 1.5)
            font.family: Style.font.family; font.pixelSize: Style.font.caption
            elide: Text.ElideRight
          }
        }
        SH.HubChip {
          id: cancel
          anchors.verticalCenter: parent.verticalCenter
          iconOnly: true
          icon: "󰅖"
          label: omod.engine.t("btn.cancel")
          danger: true
          fg: Color.foreground; accent: Color.accent; fontFamily: Style.font.family
          onClicked: omod.engine.cancelDownload()
        }
      }
      Rectangle {
        width: parent.width; height: Style.space(6); radius: height / 2
        color: SH.HubStyle.tint(Color.foreground, 0.15)
        Rectangle {
          width: omod.engine.indeterminate ? parent.width * 0.3 : parent.width * omod.engine.progress / 100
          height: parent.height; radius: height / 2
          color: Color.accent
          Behavior on width { NumberAnimation { duration: 200 } }
        }
      }
    }
  }
}
