import QtQuick
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../vendor/dailyquote/settings.js" as DQ
import "../../fonts"

// Quotes' section in the settings window: how often the quote changes and
// the translation language (the desktop quote is under Settings → Widgets).
Column {
  id: page
  property var mod: null
  spacing: SH.HubStyle.gap

  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui

  SH.HubCard {
    width: parent.width
    height: setCol.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    Column {
      id: setCol
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      spacing: Style.space(10)
      SH.HubRow {
        title: page.mod ? page.mod.t("sources") : ""; hint: page.mod ? page.mod.t("sourcesHint") : ""
        fg: page.fg; fontFamily: page.ff
      }
      Flow {
        width: parent.width
        spacing: Style.space(6)
        Repeater {
          // the built-in categories, then your own sites
          model: ["sayings", "online", "bible", "suntzu", "haiku"].concat(page.mod ? page.mod.cfg.custom.map(function(c) { return "api:" + c.id }) : [])
          delegate: SH.HubChip {
            required property string modelData
            readonly property bool picked: page.mod ? page.mod.cfg.sources.indexOf(modelData) >= 0 : modelData === "sayings"
            icon: picked ? "󰄬" : "󰅖"
            label: !page.mod ? modelData : modelData.indexOf("api:") === 0
                   ? (page.mod.cfg.custom.filter(function(c) { return "api:" + c.id === modelData })[0] || { name: "API" }).name
                   : page.mod.t(modelData)
            on: picked
            subtle: true
            h: Style.space(26)
            fg: page.fg; accent: page.accent; fontFamily: page.ff
            onClicked: page.mod.toggleSource(modelData)
          }
        }
      }
      SH.HubRow {
        title: page.mod ? page.mod.t("change") : ""; fg: page.fg; fontFamily: page.ff
        SH.HubSelect {
          width: Style.space(170); showLabel: false
          options: [15, 30, 60, 120, 240, 480, 1440].map(function(m) { return { value: String(m), label: page.mod ? page.mod.every(m) : String(m) } })
          value: page.mod ? String(page.mod.cfg.intervalMinutes) : "240"
          foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
          onChanged: function(v) { page.mod.set("intervalMinutes", parseInt(v, 10)) }
        }
      }
      SH.HubRow {
        title: page.mod ? page.mod.t("lang") : ""; fg: page.fg; fontFamily: page.ff
        SH.HubSelect {
          width: Style.space(170); showLabel: false
          options: [{ value: "ru", label: "Русский" }, { value: "en", label: "English" }]
          value: page.mod ? page.mod.cfg.lang : "ru"
          foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
          onChanged: function(v) { page.mod.set("lang", v) }
        }
      }
      SH.HubRow {
        title: page.mod ? page.mod.t("origLangs") : ""; hint: page.mod ? page.mod.t("origLangsHint") : ""
        fg: page.fg; fontFamily: page.ff
      }
      Flow {
        width: parent.width
        spacing: Style.space(6)
        Repeater {
          model: DQ.LANGS
          delegate: SH.HubChip {
            required property string modelData
            readonly property bool shownLang: page.mod ? page.mod.cfg.hideLangs.indexOf(modelData) < 0 : true
            icon: shownLang ? "󰄬" : "󰅖"
            label: DQ.langName(modelData, page.mod && page.mod.notch ? page.mod.notch.lang : "en")
            on: shownLang
            subtle: true
            h: Style.space(26)
            fg: page.fg; accent: page.accent; fontFamily: page.ff
            onClicked: page.mod.toggleLang(modelData)
          }
        }
      }
    }
  }

  // ------------------------------------------------------ your own sites
  SH.HubCard {
    width: parent.width
    height: apiCol.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    Column {
      id: apiCol
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      spacing: Style.space(8)
      SH.HubCaption { text: page.mod && page.mod.ru ? "Свои сайты с цитатами" : "Your own quote sites"; icon: "\u{f0337}"; fg: page.fg; fontFamily: page.ff }
      Text {
        width: parent.width; wrapMode: Text.Wrap
        text: page.mod && page.mod.ru ? "Адрес, который отвечает JSON, и путь к тексту и автору в нём: «quote», «0.q», «data.text». Цитаты на другом языке переводятся сами."
                                      : "An address that answers JSON, and the path to the text and author in it: “quote”, “0.q”, “data.text”. Quotes in another language get translated."
        color: Qt.darker(page.fg, 1.5); font.family: page.ff; font.pixelSize: Style.font.caption - 1
      }
      Repeater {
        model: page.mod ? page.mod.cfg.custom : []
        delegate: SH.HubRow {
          required property var modelData
          width: apiCol.width
          title: modelData.name; hint: modelData.url + "  ·  " + modelData.text + (modelData.author ? " / " + modelData.author : "")
          fg: page.fg; fontFamily: page.ff
          SH.HubChip { iconOnly: true; icon: "\u{f01b4}"; label: "×"; fg: page.fg; accent: page.accent; fontFamily: page.ff; onClicked: page.mod.removeCustom(modelData.id) }
        }
      }
      Row {
        width: parent.width
        spacing: Style.space(6)
        SH.HubField { id: apiName; width: Style.space(120); placeholderText: page.mod && page.mod.ru ? "Название" : "Name"; fg: page.fg; accent: page.accent; fontFamily: page.ff }
        SH.HubField { id: apiUrl; width: parent.width - Style.space(120) - Style.space(110) * 2 - Style.space(18); icon: "\u{f0337}"; placeholderText: "https://…"; fg: page.fg; accent: page.accent; fontFamily: page.ff }
        SH.HubField { id: apiText; width: Style.space(110); placeholderText: page.mod && page.mod.ru ? "текст: quote" : "text: quote"; fg: page.fg; accent: page.accent; fontFamily: page.ff }
        SH.HubField { id: apiAuthor; width: Style.space(110); placeholderText: page.mod && page.mod.ru ? "автор: author" : "author: author"; fg: page.fg; accent: page.accent; fontFamily: page.ff }
      }
      Row {
        spacing: Style.space(6)
        SH.HubChip {
          icon: "\u{f0e1e}"; label: page.mod && page.mod.ru ? "Проверить" : "Test"
          fg: page.fg; accent: page.accent; fontFamily: page.ff
          onClicked: if (/^https?:\/\//.test(apiUrl.text)) page.mod.testCustom(apiUrl.text.trim(), apiText.text.trim() || "quote", apiAuthor.text.trim())
        }
        SH.HubChip {
          icon: "\u{f0415}"; label: page.mod && page.mod.ru ? "Добавить" : "Add"; on: true
          fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
          onClicked: {
            if (!/^https?:\/\//.test(apiUrl.text)) return
            page.mod.addCustom({ name: apiName.text.trim() || apiUrl.text.replace(/^https?:\/\//, "").split("/")[0], url: apiUrl.text.trim(),
                                 text: apiText.text.trim() || "quote", author: apiAuthor.text.trim(), lang: "en" })
            apiName.text = ""; apiUrl.text = ""; apiText.text = ""; apiAuthor.text = ""; page.mod.testResult = null
          }
        }
      }
      Text {
        visible: !!(page.mod && page.mod.testResult)
        width: parent.width; wrapMode: Text.Wrap
        readonly property var r: page.mod ? page.mod.testResult : null
        text: !r ? "" : r.busy ? "…" : r.ok ? "«" + r.quote.text + "»" + (r.quote.author ? " — " + r.quote.author : "") : (page.mod.ru ? "Не вышло: " : "Didn't work: ") + r.error
        color: r && r.ok ? page.fg : Color.urgent; font.family: page.ff; font.pixelSize: Style.font.caption
      }
    }
  }
}
