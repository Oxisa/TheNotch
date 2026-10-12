import QtQuick
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// The clock widget's other looks (besides Kronos's rings):
//   type  big typographic time and the date in words under it
//   flip  flip-clock cards; a card flips when its digits change
//   day   a ring of the day: how much of it has passed, the time inside
// Looks after rover-001/whimsy's clocks and day progress (MIT); no code taken.
Item {
  id: c
  property string look: "type"
  property bool use24h: true
  property bool showDate: true
  property real size: 1
  property bool ru: true
  property bool vertical: false                // hours over minutes
  property string digitFont: ""                // "" = the theme's font
  readonly property string tf: digitFont || ff
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.desk

  property date now: new Date()
  Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: c.now = new Date() }
  readonly property int hh: use24h ? now.getHours() : ((now.getHours() + 11) % 12 + 1)
  readonly property string hStr: (hh < 10 && use24h ? "0" : "") + hh
  readonly property string mStr: (now.getMinutes() < 10 ? "0" : "") + now.getMinutes()
  readonly property string dateWords: {
    var days = ru ? ["воскресенье", "понедельник", "вторник", "среда", "четверг", "пятница", "суббота"]
                  : ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    var months = ru ? ["января", "февраля", "марта", "апреля", "мая", "июня", "июля", "августа", "сентября", "октября", "ноября", "декабря"]
                    : ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    return ru ? days[now.getDay()] + ", " + now.getDate() + " " + months[now.getMonth()]
              : days[now.getDay()] + ", " + months[now.getMonth()] + " " + now.getDate()
  }
  readonly property real dayShare: (now.getHours() * 3600 + now.getMinutes() * 60 + now.getSeconds()) / 86400

  width: look === "day" ? dayBox.width : look === "flip" ? flipCol.implicitWidth : typeCol.implicitWidth
  height: look === "day" ? dayBox.height : look === "flip" ? flipCol.implicitHeight : typeCol.implicitHeight

  // --------------------------------------------------------------- type
  Column {
    id: typeCol
    visible: c.look === "type"
    spacing: Style.space(2) * c.size
    Text {
      anchors.horizontalCenter: c.vertical ? parent.horizontalCenter : undefined
      text: c.vertical ? c.hStr + "\n" + c.mStr : c.hStr + ":" + c.mStr
      horizontalAlignment: Text.AlignHCenter
      lineHeight: c.vertical ? 0.85 : 1
      color: "white"
      font.family: c.tf; font.pixelSize: Math.round(Style.space(96) * c.size); font.bold: true
      font.letterSpacing: -2
      style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.45)
    }
    Text {
      visible: c.showDate
      anchors.horizontalCenter: c.vertical ? parent.horizontalCenter : undefined
      leftPadding: c.vertical ? 0 : Style.space(6)
      width: c.vertical ? Style.space(150) * c.size : implicitWidth
      wrapMode: Text.WordWrap
      horizontalAlignment: c.vertical ? Text.AlignHCenter : Text.AlignLeft
      text: c.dateWords
      color: Qt.rgba(1, 1, 1, 0.8)
      font.family: c.ff; font.pixelSize: Math.round(Style.space(20) * c.size)
      style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.45)
    }
  }

  // --------------------------------------------------------------- flip
  component FlipCard: Item {
    id: fc
    property string value: "00"
    property real s: 1
    width: Style.space(96) * s; height: Style.space(110) * s
    Rectangle {
      anchors.fill: parent
      radius: Style.space(12) * fc.s
      color: Qt.rgba(c.bgc.r, c.bgc.g, c.bgc.b, 0.9)
      border.width: 1; border.color: SH.HubStyle.tint(c.fg, 0.08)
    }
    Text {
      id: digits
      anchors.centerIn: parent
      text: fc.value
      color: c.fg
      font.family: c.tf; font.pixelSize: Style.space(64) * fc.s; font.bold: true
    }
    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 2; color: Qt.rgba(0, 0, 0, 0.45) }
    // the flip: the top half folds down when the value changes
    Rectangle {
      id: leaf
      width: parent.width; height: parent.height / 2
      radius: Style.space(12) * fc.s
      color: SH.HubStyle.tint(c.accent, 0.35)
      opacity: 0
      transform: Rotation { id: rot; origin.x: leaf.width / 2; origin.y: leaf.height; axis { x: 1; y: 0; z: 0 } angle: 0 }
    }
    onValueChanged: flip.restart()
    SequentialAnimation {
      id: flip
      PropertyAction { target: leaf; property: "opacity"; value: 0.9 }
      NumberAnimation { target: rot; property: "angle"; from: 0; to: -180; duration: 380; easing.type: Easing.InOutQuad }
      PropertyAction { target: leaf; property: "opacity"; value: 0 }
      PropertyAction { target: rot; property: "angle"; value: 0 }
    }
  }
  Column {
    id: flipCol
    visible: c.look === "flip"
    spacing: Style.space(8) * c.size
    Grid {
      anchors.horizontalCenter: parent.horizontalCenter
      columns: c.vertical ? 1 : 2
      spacing: Style.space(8) * c.size
      FlipCard { value: c.hStr; s: c.size }
      FlipCard { value: c.mStr; s: c.size }
    }
    Text {
      visible: c.showDate
      anchors.horizontalCenter: parent.horizontalCenter
      width: c.vertical ? Style.space(96) * c.size : implicitWidth
      wrapMode: Text.WordWrap
      horizontalAlignment: Text.AlignHCenter
      text: c.dateWords
      color: Qt.rgba(1, 1, 1, 0.8)
      font.family: c.ff; font.pixelSize: Math.round(Style.space(16) * c.size)
      style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.45)
    }
  }

  // ---------------------------------------------------------------- day
  Rectangle {
    id: dayBox
    visible: c.look === "day"
    width: Style.space(200) * c.size; height: width
    radius: width / 2
    color: Qt.rgba(c.bgc.r, c.bgc.g, c.bgc.b, 0.6)
    Canvas {
      id: dayRing
      anchors.fill: parent
      onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        var r = width / 2 - Style.space(10) * c.size, cx = width / 2
        ctx.lineWidth = Style.space(10) * c.size; ctx.lineCap = "round"
        ctx.strokeStyle = SH.HubStyle.tint(c.fg, 0.12)
        ctx.beginPath(); ctx.arc(cx, cx, r, 0, Math.PI * 2); ctx.stroke()
        ctx.strokeStyle = c.accent
        ctx.beginPath(); ctx.arc(cx, cx, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * c.dayShare); ctx.stroke()
        for (var h = 0; h < 24; h += 6) {                      // 0, 6, 12, 18 ticks
          var a = -Math.PI / 2 + Math.PI * 2 * h / 24
          ctx.fillStyle = SH.HubStyle.tint(c.fg, 0.5)
          ctx.beginPath(); ctx.arc(cx + Math.cos(a) * (r - Style.space(16) * c.size), cx + Math.sin(a) * (r - Style.space(16) * c.size), 2, 0, Math.PI * 2); ctx.fill()
        }
      }
      Connections { target: c; function onDayShareChanged() { dayRing.requestPaint() } }
      Component.onCompleted: requestPaint()
    }
    Column {
      anchors.centerIn: parent
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: c.hStr + ":" + c.mStr
        color: c.fg
        font.family: c.tf; font.pixelSize: Math.round(Style.space(40) * c.size); font.bold: true
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Math.round(c.dayShare * 100) + "% " + (c.ru ? "дня" : "of the day")
        color: Qt.darker(c.fg, 1.4)
        font.family: c.ff; font.pixelSize: Math.round(Style.space(13) * c.size)
      }
    }
  }
}
