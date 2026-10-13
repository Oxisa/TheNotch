import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."
import "../../vendor/omaloader" as OL
import "../../vendor/soundhub" as SH
import "../../fonts"

// Omaloader as a TheNotch dashboard: the engine and UI from vendor/omaloader,
// settings in TheNotch's file (modules.omaloader).
//   live   while downloading: download glyph · percent (above music)
//   peek   what's downloading, progress, cancel
// "Done" needs no event of its own: Omaloader's notification shows in the
// notch through the notifications module.
NotchModule {
  id: omod
  title: notch && notch.lang === "ru" ? "Загрузки" : "Downloads"
  icon: "󰇚"
  description: notch && notch.lang === "ru" ? "Скачивание видео, звука и GIF по ссылке" : "Download video, audio and GIFs from a link"
  sectionOrder: 1
  pageWidth: 400
  page: Component { OL.Content { host: omod.engine; only: "download" } }
  settingsSection: "tools"
  settingsPage: Component { OL.Content { host: omod.engine; only: "settings" } }

  property var engine: OL.Engine {
    settings: omod.notch && omod.notch.settings.modules && omod.notch.settings.modules.omaloader
              ? omod.notch.settings.modules.omaloader : ({})
    onPersistRequested: function(values) { if (omod.notch) omod.notch.modulePersist("omaloader", values) }
    langOverride: omod.notch ? omod.notch.lang : ""
    ff: Fonts.ui
  }

  // ------------------------------------------------------------- live
  live: engine.running
  livePriority: 20
  readonly property string pct: engine.indeterminate ? "…" : Math.round(engine.progress) + "%"

  liveLeft: Component {
    Text {
      text: "󰇚"
      color: Color.accent
      font.family: Fonts.ui; font.pixelSize: Style.font.body + 2
      SequentialAnimation on opacity {
        running: omod.engine.running; loops: Animation.Infinite
        NumberAnimation { from: 1; to: 0.35; duration: 650; easing.type: Easing.InOutQuad }
        NumberAnimation { from: 0.35; to: 1; duration: 650; easing.type: Easing.InOutQuad }
      }
    }
  }
  // iOS-style: the percent and a ring that fills (spins while unknown)
  liveRight: Component {
    Row {
      spacing: Style.space(6)
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: omod.pct
        color: Color.foreground
        font.family: Fonts.ui; font.pixelSize: Style.font.caption; font.bold: true
      }
      Canvas {
        id: ring
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(18); height: width
        readonly property real p: omod.engine.indeterminate ? 0.25 : omod.engine.progress / 100
        readonly property color tone: Color.accent
        onPChanged: requestPaint()
        onToneChanged: requestPaint()
        onPaint: {
          var c = getContext("2d"), r = width / 2 - 2
          c.reset(); c.lineWidth = 2.5; c.lineCap = "round"
          c.strokeStyle = Qt.rgba(tone.r, tone.g, tone.b, 0.25)
          c.beginPath(); c.arc(width / 2, height / 2, r, 0, Math.PI * 2); c.stroke()
          c.strokeStyle = tone
          c.beginPath(); c.arc(width / 2, height / 2, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.max(0.02, p)); c.stroke()
        }
        RotationAnimator on rotation { from: 0; to: 360; duration: 1000; loops: Animation.Infinite; running: omod.engine.indeterminate }
      }
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
          font.family: Fonts.ui; font.pixelSize: Style.space(22)
        }
        Column {
          width: parent.width - Style.space(32) - cancel.width - parent.spacing * 2
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(2)
          Text {
            width: parent.width
            text: omod.engine.previewTitle || omod.engine.url
            color: Color.foreground
            font.family: Fonts.ui; font.pixelSize: Style.font.body; font.bold: true
            elide: Text.ElideRight
          }
          Text {
            width: parent.width
            text: omod.engine.statusText
            color: Qt.darker(Color.foreground, 1.5)
            font.family: Fonts.ui; font.pixelSize: Style.font.caption
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
          fg: Color.foreground; accent: Color.accent; fontFamily: Fonts.ui
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
