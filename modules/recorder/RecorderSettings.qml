import QtQuick
import Quickshell
import qs.Commons
import "../../../osia.soundhub" as SH

// Recorder's section in the settings window: the transcription model (and
// its download), the language, auto-transcribe.
Column {
  id: page
  property var mod: null
  spacing: SH.HubStyle.gap
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Style.font.family
  function t(a, b) { return mod ? mod.t(a, b) : b }
  Component.onCompleted: if (mod) mod.refresh()

  SH.HubCard {
    width: parent.width
    height: col.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    Column {
      id: col
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      spacing: Style.space(10)
      SH.HubRow {
        title: page.t("Модель расшифровки", "Transcription model")
        hint: page.t("Whisper через voxtype, всё на этом компьютере. base — быстро, small — баланс, large-v3-turbo — точнее всего",
                     "Whisper via voxtype, all on this machine. base is fast, small balanced, large-v3-turbo the most accurate")
        fg: page.fg; fontFamily: page.ff
        SH.HubSelect {
          width: Style.space(200); showLabel: false
          options: (page.mod ? page.mod.st.catalog || [] : []).map(function(m) {
            var have = page.mod.st.models.indexOf(m.name) >= 0
            return { value: m.name, label: m.label + (have ? "  ✓" : "  · " + m.size + page.t(" МБ", " MB")) } })
          value: page.mod ? page.mod.model : "small"
          foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
          onChanged: function(v) { page.mod.persist({ model: v }) }
        }
      }
      SH.HubRow {
        visible: page.mod && !page.mod.hasModel
        title: page.mod && page.mod.st.download ? page.t("Скачивается ", "Downloading ") + page.mod.st.download.model + "…"
                                                : page.t("Модель не скачана", "The model isn't downloaded")
        fg: page.fg; fontFamily: page.ff
        SH.HubChip {
          visible: page.mod && !page.mod.st.download
          icon: "\u{f01da}"; label: page.t("Скачать", "Download")
          on: true
          fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
          onClicked: page.mod.cmd(["download", page.mod.model])
        }
      }
      SH.HubRow {
        title: page.t("Язык речи", "Speech language"); fg: page.fg; fontFamily: page.ff
        SH.HubSelect {
          width: Style.space(200); showLabel: false
          options: [{ value: "auto", label: page.t("Определять сам", "Detect") }, { value: "ru", label: "Русский" }, { value: "en", label: "English" }]
          value: page.mod ? page.mod.lang : "auto"
          foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
          onChanged: function(v) { page.mod.persist({ lang: v }) }
        }
      }
      SH.HubRow {
        title: page.t("Расшифровывать сразу", "Transcribe right away")
        hint: page.t("После остановки записи", "When a recording stops")
        fg: page.fg; fontFamily: page.ff
        SH.HubSwitch {
          checked: page.mod ? page.mod.opt("autoTranscribe", false) === true : false
          fg: page.fg; accent: page.accent; ink: page.bgc
          onToggled: page.mod.persist({ autoTranscribe: !checked })
        }
      }
    }
  }
}
