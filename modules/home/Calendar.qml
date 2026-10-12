import QtQuick
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// The month, Monday first, today in the accent colour; ‹ › step months,
// a click on the title comes back to this month.
Column {
  id: cal
  property bool ru: true
  // events (the Calendar module): dots under the days; a picked day is ringed
  property var source: null
  property var picked: null
  property real rowH: Style.space(25)
  signal pick(date day)
  property date today: new Date()
  property int shift: 0                         // months away from today's
  Timer { interval: 60000; running: true; repeat: true; onTriggered: cal.today = new Date() }
  readonly property date shown: new Date(today.getFullYear(), today.getMonth() + shift, 1)
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property string ff: Fonts.ui
  readonly property var names: ru ? ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"] : ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
  readonly property var days: {
    var y = shown.getFullYear(), m = shown.getMonth()
    var first = (new Date(y, m, 1).getDay() + 6) % 7, count = new Date(y, m + 1, 0).getDate(), prev = new Date(y, m, 0).getDate()
    var out = []
    for (var i = 0; i < 42; i++) {
      var d = i - first + 1
      out.push(d < 1 ? { n: prev + d, inMonth: false } : d > count ? { n: d - count, inMonth: false }
                     : { n: d, inMonth: true, today: shift === 0 && d === today.getDate(), weekend: i % 7 >= 5 })
    }
    return out.length > 35 && !out[35].inMonth ? out.slice(0, 35) : out
  }
  spacing: Style.space(4)
  readonly property real cell: width / 7

  Item {
    width: parent.width; height: Style.space(22)
    Text {
      anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
      text: (cal.ru ? ["Январь", "Февраль", "Март", "Апрель", "Май", "Июнь", "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"]
                    : ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"])[cal.shown.getMonth()]
            + " " + cal.shown.getFullYear()
      color: cal.fg
      font.family: cal.ff; font.pixelSize: Style.font.caption + 1; font.bold: true; font.capitalization: Font.Capitalize
      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: cal.shift = 0 }
    }
    Row {
      anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(4)
      Repeater {
        model: [{ g: "\u{f0141}", d: -1 }, { g: "\u{f0142}", d: 1 }]
        delegate: Text {
          required property var modelData
          text: modelData.g
          color: am.containsMouse ? cal.accent : Qt.darker(cal.fg, 1.3)
          font.family: cal.ff; font.pixelSize: Style.font.body + 2
          MouseArea { id: am; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: cal.shift += modelData.d }
        }
      }
    }
  }
  Row {
    Repeater {
      model: cal.names
      delegate: Text {
        required property string modelData
        required property int index
        width: cal.cell
        horizontalAlignment: Text.AlignHCenter
        text: modelData
        color: index >= 5 ? Qt.darker(cal.accent, 1.1) : Qt.darker(cal.fg, 1.5)
        font.family: cal.ff; font.pixelSize: Style.font.caption - 2; font.bold: true
      }
    }
  }
  Grid {
    columns: 7
    Repeater {
      model: cal.days
      delegate: Item {
        id: dayCell
        required property var modelData
        width: cal.cell; height: cal.rowH
        readonly property date day: new Date(cal.shown.getFullYear(), cal.shown.getMonth(), modelData.n)
        readonly property var evs: cal.source && modelData.inMonth ? cal.source.eventsOn(day) : []
        readonly property bool isPicked: !!(cal.picked && modelData.inMonth && cal.picked.getFullYear() === day.getFullYear()
                                            && cal.picked.getMonth() === day.getMonth() && cal.picked.getDate() === day.getDate())
        Rectangle {
          anchors.centerIn: parent
          width: Math.min(parent.width, Style.space(25)) - 2; height: width; radius: width / 2
          visible: !!dayCell.modelData.today || dayCell.isPicked
          color: dayCell.modelData.today ? cal.accent : "transparent"
          border.width: dayCell.isPicked && !dayCell.modelData.today ? 2 : 0
          border.color: cal.accent
        }
        Text {
          anchors.centerIn: parent
          text: dayCell.modelData.n
          color: dayCell.modelData.today ? Color.background : !dayCell.modelData.inMonth ? Qt.darker(cal.fg, 2.6)
               : dayCell.modelData.weekend ? cal.accent : cal.fg
          font.family: cal.ff; font.pixelSize: Style.font.caption; font.bold: !!dayCell.modelData.today
        }
        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          spacing: 2
          Repeater {
            model: dayCell.evs.slice(0, 3)
            delegate: Rectangle { required property var modelData; width: 4; height: 4; radius: 2; color: cal.source.colorOf(modelData) }
          }
        }
        MouseArea { anchors.fill: parent; enabled: dayCell.modelData.inMonth && cal.source !== null; cursorShape: Qt.PointingHandCursor; onClicked: cal.pick(dayCell.day) }
      }
    }
  }
}
