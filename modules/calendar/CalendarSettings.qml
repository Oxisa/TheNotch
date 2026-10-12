import QtQuick
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// Settings → Apps → Calendar: subscriptions (an iCal link per calendar) and
// how long before an event to remind.
Column {
  id: page
  property var mod: null
  spacing: SH.HubStyle.gap
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }

  SH.HubCard {
    width: page.width
    height: col.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    Column {
      id: col
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      spacing: Style.space(10)
      SH.HubCaption { text: page.t("Подписки", "Subscriptions"); icon: "\u{f00f0}"; fg: page.fg; fontFamily: page.ff }
      Text {
        width: parent.width; wrapMode: Text.Wrap
        text: page.t("Ссылка iCal из настроек календаря: Google — «Секретный адрес в формате iCal», Outlook — «Опубликовать календарь → ICS», iCloud — «Общий календарь → публичная ссылка». Вход в аккаунт не нужен.",
                     "The iCal link from the calendar's settings: Google — “Secret address in iCal format”, Outlook — “Publish a calendar → ICS”, iCloud — “Public calendar”. No sign-in.")
        color: Qt.darker(page.fg, 1.5); font.family: page.ff; font.pixelSize: Style.font.caption - 1
      }
      Repeater {
        model: page.mod ? page.mod.subs : []
        delegate: SH.HubRow {
          required property var modelData
          required property int index
          title: modelData.name
          hint: modelData.url.replace(/(secret|private)[^/]*/i, "…").slice(0, 60)
          fg: page.fg; fontFamily: page.ff
          Row {
            spacing: Style.space(6)
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Style.space(14); height: width; radius: width / 2; color: modelData.color || page.accent }
            SH.HubChip {
              iconOnly: true; icon: "\u{f01b4}"; label: page.t("Удалить", "Remove")
              fg: page.fg; accent: page.accent; fontFamily: page.ff
              onClicked: { var l = page.mod.subs.slice(); l.splice(index, 1); page.mod.saveSubs(l) }
            }
          }
        }
      }
      Repeater {
        model: page.mod ? page.mod.errors : []
        delegate: Text { required property var modelData; text: modelData.cal + ": " + page.t("не загрузилось", "didn't load"); color: Color.urgent; font.family: page.ff; font.pixelSize: Style.font.caption }
      }
      Row {
        width: parent.width
        spacing: Style.space(6)
        SH.HubField { id: nm; width: Style.space(140); placeholderText: page.t("Название", "Name"); fg: page.fg; accent: page.accent; fontFamily: page.ff }
        SH.HubField { id: url; width: parent.width - nm.width - add.width - Style.space(12); icon: "\u{f0337}"; placeholderText: "https://…/basic.ics"; fg: page.fg; accent: page.accent; fontFamily: page.ff; onAccepted: add.clicked() }
        SH.HubChip {
          id: add
          icon: "\u{f0415}"; label: page.t("Добавить", "Add")
          on: true
          fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
          onClicked: {
            var u = url.text.trim()
            if (!/^(https?|webcal):\/\//.test(u)) return
            var l = page.mod.subs.slice()
            l.push({ name: nm.text.trim() || page.t("Календарь ", "Calendar ") + (l.length + 1), url: u, color: page.mod.palette[l.length % page.mod.palette.length] })
            page.mod.saveSubs(l); nm.text = ""; url.text = ""
          }
        }
      }
    }
  }
  SH.HubCard {
    width: page.width
    height: rem.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    SH.HubRow {
      id: rem
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      icon: "\u{f009a}"
      title: page.t("Напоминать о событии", "Remind before an event"); hint: page.t("В чёлке; у созвона — кнопка «Войти»", "In the notch; a call gets a Join button")
      fg: page.fg; fontFamily: page.ff
      SH.HubSelect {
        width: Style.space(160); showLabel: false
        options: [0, 5, 10, 15, 30, 60].map(function(m) { return { value: String(m), label: m ? page.t("за ", "") + m + page.t(" мин", " min before") : page.t("Не напоминать", "Never") } })
        value: page.mod ? String(page.mod.remind) : "10"
        foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
        onChanged: function(v) { page.mod.persist({ remind: parseInt(v, 10) }) }
      }
    }
  }
}
