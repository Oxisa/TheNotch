import QtQuick
import Quickshell
import qs.Commons
import "../home"
import "../../vendor/soundhub" as SH
import "../../fonts"

// Calendar's page: the month on the left (dots for events, click a day),
// the picked day's events on the right (Join for calls, your own can be
// deleted), and a line to add your own event.
Row {
  id: page
  property var mod: null
  spacing: Style.space(12)
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }
  readonly property var day: mod ? mod.picked : new Date()
  readonly property var list: mod ? mod.eventsOn(day) : []

  Rectangle {
    width: Style.space(280); height: Style.space(290)
    radius: SH.HubStyle.radius + Style.space(2)
    color: SH.HubStyle.tint(page.fg, 0.05)
    Calendar {
      anchors.fill: parent; anchors.margins: Style.space(14)
      ru: page.mod ? page.mod.ru : true
      source: page.mod
      picked: page.day
      rowH: Style.space(36)
      onPick: function(d) { page.mod.picked = d }
    }
  }

  Column {
    width: page.width - Style.space(292)
    spacing: Style.space(8)
    Text {
      text: { var s = page.day.toLocaleDateString(Qt.locale(page.mod && page.mod.ru ? "ru_RU" : "en_US"), "dddd, d MMMM"); return s.charAt(0).toUpperCase() + s.slice(1) }
      color: page.fg; font.family: page.ff; font.pixelSize: Style.font.body + 1; font.bold: true
    }
    Text {
      visible: page.list.length === 0
      text: page.t("Событий нет", "No events")
      color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption
    }
    Repeater {
      model: page.list
      delegate: Rectangle {
        id: ev
        required property var modelData
        width: parent.width; height: Style.space(54)
        radius: SH.HubStyle.radiusSmall + Style.space(2)
        color: SH.HubStyle.tint(page.fg, 0.05)
        Rectangle { x: Style.space(8); anchors.verticalCenter: parent.verticalCenter; width: 4; height: parent.height - Style.space(16); radius: 2; color: page.mod.colorOf(ev.modelData) }
        Column {
          x: Style.space(20); anchors.verticalCenter: parent.verticalCenter
          width: parent.width - Style.space(28) - acts.width
          Text { width: parent.width; elide: Text.ElideRight; text: ev.modelData.title; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.body; font.bold: true }
          Text {
            width: parent.width; elide: Text.ElideRight
            text: page.mod.timeOf(ev.modelData) + (ev.modelData.where && !ev.modelData.where.startsWith("http") ? " · " + ev.modelData.where : "") + " · " + (ev.modelData.own ? page.t("моё", "mine") : ev.modelData.cal)
            color: Qt.darker(page.fg, 1.5); font.family: page.ff; font.pixelSize: Style.font.caption - 1
          }
        }
        Row {
          id: acts
          anchors.right: parent.right; anchors.rightMargin: Style.space(8); anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(4)
          SH.HubChip { visible: !!ev.modelData.link; icon: "\u{f0567}"; label: page.t("Войти", "Join"); on: true; h: Style.space(26)
                       fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff; onClicked: Quickshell.execDetached(["xdg-open", ev.modelData.link]) }
          SH.HubChip { visible: !!ev.modelData.own; iconOnly: true; icon: "\u{f01b4}"; label: page.t("Удалить", "Delete"); h: Style.space(26)
                       fg: page.fg; accent: page.accent; fontFamily: page.ff; onClicked: page.mod.remove(ev.modelData.id) }
        }
      }
    }
    // your own event on the picked day
    Rectangle { width: parent.width; height: 1; color: SH.HubStyle.tint(page.fg, 0.08) }
    Row {
      width: parent.width
      spacing: Style.space(6)
      SH.HubField {
        id: when
        width: Style.space(84)
        icon: "\u{f0150}"
        placeholderText: "10:00"
        fg: page.fg; accent: page.accent; fontFamily: page.ff
      }
      SH.HubField {
        id: what
        width: parent.width - when.width - addBtn.width - Style.space(12)
        icon: "\u{f0415}"
        placeholderText: page.t("Новое событие…", "New event…")
        fg: page.fg; accent: page.accent; fontFamily: page.ff
        onAccepted: addBtn.clicked()
      }
      SH.HubChip {
        id: addBtn
        iconOnly: true; icon: "\u{f0415}"; label: page.t("Добавить", "Add")
        on: true
        fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
        onClicked: {
          if (!what.text.trim()) return
          var m = when.text.match(/^(\d{1,2})[:.](\d{2})$/), d = page.day, all = !m
          var start = new Date(d.getFullYear(), d.getMonth(), d.getDate(), m ? +m[1] : 0, m ? +m[2] : 0)
          var iso = function(x) { return Qt.formatDateTime(x, "yyyy-MM-ddTHH:mm:ss") }
          page.mod.add({ title: what.text.trim(), start: iso(start), end: iso(new Date(start.getTime() + (all ? 86400000 : 3600000))), allDay: all })
          what.text = ""; when.text = ""
        }
      }
    }
    Text {
      text: page.t("Время пустое — событие на весь день", "No time — an all-day event")
      color: Qt.darker(page.fg, 1.7); font.family: page.ff; font.pixelSize: Style.font.caption - 2
    }
  }
}
