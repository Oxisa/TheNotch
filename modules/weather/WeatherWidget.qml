import QtQuick
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../DeskStyle.js" as DS
import "../../fonts"

// The weather on the desktop, in one of three looks:
//   capsule  a compact pill: glyph, temperature, city
//   card     big temperature, the city in capitals, what's outside,
//            feels-like, wind and humidity, today's low/high
//   line     one clean line of text, no background
//   full     big temperature and feels-like, the city and what's outside,
//            the next four hours; tinted by the weather
//   round    a circle: glyph, temperature, what's outside
//   tile     a small square: glyph and temperature
// The last three are after the weather faces of ilyamiro/serpantinum — the
// look only, no code taken (it is AGPL).
Item {
  id: w
  property var mod: null
  property bool editing: false
  property bool deskVertical: false        // turned 90°: capsule and line stack up, the card stays
  readonly property bool deskShown: (mod && mod.now !== null) || editing
  readonly property string look: mod ? mod.look : "capsule"
  readonly property var n: mod ? mod.now : null
  readonly property string city: mod && mod.place ? mod.place.name : (mod ? mod.t("Город не выбран", "No city set") : "")
  property var deskStyle: ({})
  readonly property color fg: DS.fg(deskStyle, Color.foreground)
  readonly property color accent: DS.accent(deskStyle, Color.accent)
  readonly property color bg: Color.background
  readonly property string ff: Fonts.desk
  readonly property real alpha: Number(DS.pick(deskStyle, "bgOpacity", mod ? Number(mod.opt("opacity", 0.85)) : 0.85))
  readonly property color fill: DS.bg(deskStyle, bg, accent, alpha)
  readonly property string g: n ? mod.glyph(n.code, n.day) : "\u{f0595}"
  readonly property string temp: n ? mod.deg(n.temp) : "—"

  readonly property var box: look === "card" ? cardBox : look === "line" ? lineRow : look === "full" ? fullBox
                           : look === "round" ? roundBox : look === "tile" ? tileBox : capsule
  width: look === "line" ? lineRow.implicitWidth : box.width
  height: look === "line" ? lineRow.implicitHeight : box.height
  // the looks after serpantinum (full, round, tile) take a colour from the weather
  readonly property color tone: n ? mod.tone(n.code, n.day) : accent

  // ------------------------------------------------------------ capsule
  Rectangle {
    id: capsule
    visible: w.look === "capsule"
    width: capRow.implicitWidth + Style.space(w.deskVertical ? 22 : 32)
    height: capRow.implicitHeight + Style.space(w.deskVertical ? 32 : 18)
    radius: Math.min(width, height) / 2
    color: w.fill
    border.width: 1
    border.color: DS.border(w.deskStyle, w.fg)
    Row {
      id: capRow
      anchors.centerIn: parent
      spacing: Style.space(10)
      Text { text: w.g; color: w.accent; font.family: w.ff; font.pixelSize: Style.space(22) }
      Text { text: w.temp; color: w.fg; font.family: w.ff; font.pixelSize: Style.space(20); font.bold: true }
      Text { text: w.city; color: Qt.darker(w.fg, 1.4); font.family: w.ff; font.pixelSize: Style.font.caption }
    }
  }

  // --------------------------------------------------------------- card
  Rectangle {
    id: cardBox
    visible: w.look === "card"
    width: Style.space(260)
    height: cardCol.implicitHeight + Style.space(32)
    radius: DS.radius(w.deskStyle, SH.HubStyle.radius + Style.space(4))
    topLeftRadius: DS.corner(w.deskStyle, "tl", SH.HubStyle.radius + Style.space(4))
    topRightRadius: DS.corner(w.deskStyle, "tr", SH.HubStyle.radius + Style.space(4))
    bottomLeftRadius: DS.corner(w.deskStyle, "bl", SH.HubStyle.radius + Style.space(4))
    bottomRightRadius: DS.corner(w.deskStyle, "br", SH.HubStyle.radius + Style.space(4))
    color: w.fill
    border.width: 1
    border.color: DS.border(w.deskStyle, w.fg)
    Column {
      id: cardCol
      x: Style.space(18); y: Style.space(16)
      width: parent.width - Style.space(36)
      spacing: Style.space(4)
      Text {
        width: parent.width
        text: w.city.toUpperCase()
        color: Qt.darker(w.fg, 1.4)
        font.family: w.ff; font.pixelSize: Style.font.caption - 1; font.bold: true; font.letterSpacing: 1.6
        elide: Text.ElideRight
      }
      Row {
        spacing: Style.space(12)
        Text { text: w.temp; color: w.fg; font.family: w.ff; font.pixelSize: Style.space(52); font.bold: true }
        Text { anchors.verticalCenter: parent.verticalCenter; text: w.g; color: w.accent; font.family: w.ff; font.pixelSize: Style.space(38) }
      }
      Text {
        text: w.n ? w.mod.words(w.n.code) : ""
        color: w.fg
        font.family: w.ff; font.pixelSize: Style.font.body
      }
      Text {
        text: w.n ? w.mod.t("ощущается ", "feels ") + w.mod.deg(w.n.feels) + "  ·  " + w.mod.deg(w.n.lo) + " … " + w.mod.deg(w.n.hi) : ""
        color: Qt.darker(w.fg, 1.5)
        font.family: w.ff; font.pixelSize: Style.font.caption - 1
      }
      Text {
        text: w.n ? "\u{f059d} " + Math.round(w.n.wind) + w.mod.t(" км/ч", " km/h") + "   \u{f058e} " + Math.round(w.n.hum) + "%" : ""
        color: Qt.darker(w.fg, 1.5)
        font.family: w.ff; font.pixelSize: Style.font.caption - 1
      }
    }
  }

  // --------------------------------------------------------------- line
  Grid {
    id: lineRow
    visible: w.look === "line"
    columns: w.deskVertical ? 1 : 99
    horizontalItemAlignment: Grid.AlignHCenter
    verticalItemAlignment: Grid.AlignVCenter
    spacing: Style.space(10)
    Text { text: w.g; color: w.accent; font.family: w.ff; font.pixelSize: Style.space(26); style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.55) }
    Text { text: w.temp; color: "white"; font.family: w.ff; font.pixelSize: Style.space(26); font.bold: true; style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.55) }
    Text {
      text: (w.n ? w.mod.words(w.n.code) + (w.deskVertical ? "\n" : "  ·  ") : "") + w.city
      horizontalAlignment: Text.AlignHCenter
      color: Qt.rgba(1, 1, 1, 0.8)
      font.family: w.ff; font.pixelSize: Style.font.body
      style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.55)
    }
  }

  // --------------------------------------------------------------- full
  Rectangle {
    id: fullBox
    visible: w.look === "full"
    width: Style.space(330)
    height: fullCol.implicitHeight + Style.space(32)
    radius: DS.radius(w.deskStyle, Style.space(22))
    topLeftRadius: DS.corner(w.deskStyle, "tl", Style.space(22))
    topRightRadius: DS.corner(w.deskStyle, "tr", Style.space(22))
    bottomLeftRadius: DS.corner(w.deskStyle, "bl", Style.space(22))
    bottomRightRadius: DS.corner(w.deskStyle, "br", Style.space(22))
    color: w.fill
    border.width: 1
    border.color: Qt.rgba(w.tone.r, w.tone.g, w.tone.b, 0.35)
    Rectangle {                                    // a wash of the weather's colour
      anchors.fill: parent; radius: parent.radius
      gradient: Gradient {
        GradientStop { position: 0; color: Qt.rgba(w.tone.r, w.tone.g, w.tone.b, 0.20) }
        GradientStop { position: 1; color: "transparent" }
      }
    }
    Column {
      id: fullCol
      x: Style.space(20); y: Style.space(16)
      width: parent.width - Style.space(40)
      spacing: Style.space(12)
      Item {
        width: parent.width; height: Math.max(leftTop.implicitHeight, rightTop.implicitHeight)
        Row {
          id: leftTop
          spacing: Style.space(12)
          Text { anchors.verticalCenter: parent.verticalCenter; text: w.g; color: w.tone; font.family: w.ff; font.pixelSize: Style.space(52) }
          Column {
            anchors.verticalCenter: parent.verticalCenter
            Text { text: w.temp; color: w.fg; font.family: w.ff; font.pixelSize: Style.space(40); font.bold: true }
            Text { text: w.n ? w.mod.t("ощущается ", "feels like ") + w.mod.deg(w.n.feels) : ""; color: Qt.darker(w.fg, 1.4); font.family: w.ff; font.pixelSize: Style.font.caption - 1 }
          }
        }
        Column {
          id: rightTop
          anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
          width: parent.width - leftTop.implicitWidth - Style.space(12)
          Text { width: parent.width; horizontalAlignment: Text.AlignRight; elide: Text.ElideRight; text: w.city; color: w.fg; font.family: w.ff; font.pixelSize: Style.font.body; font.bold: true }
          Text { width: parent.width; horizontalAlignment: Text.AlignRight; wrapMode: Text.WordWrap; text: w.n ? w.mod.words(w.n.code) : ""; color: w.tone; font.family: w.ff; font.pixelSize: Style.font.caption }
        }
      }
      Rectangle { width: parent.width; height: 1; color: Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.10); visible: hoursRow.visible }
      Row {
        id: hoursRow
        visible: !!(w.n && w.n.hours && w.n.hours.length)
        width: parent.width
        Repeater {
          model: w.n && w.n.hours ? w.n.hours : []
          delegate: Column {
            required property var modelData
            width: hoursRow.width / Math.max(1, w.n.hours.length)
            spacing: Style.space(4)
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: w.mod.deg(modelData.temp); color: w.fg; font.family: w.ff; font.pixelSize: Style.font.body; font.bold: true }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: w.mod.glyph(modelData.code, modelData.day); color: w.mod.tone(modelData.code, modelData.day); font.family: w.ff; font.pixelSize: Style.space(24) }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.hour; color: Qt.darker(w.fg, 1.5); font.family: w.ff; font.pixelSize: Style.font.caption - 1 }
          }
        }
      }
    }
  }

  // -------------------------------------------------------------- round
  Rectangle {
    id: roundBox
    visible: w.look === "round"
    width: Style.space(190); height: width; radius: width / 2
    color: w.fill
    border.width: 3
    border.color: Qt.rgba(w.tone.r, w.tone.g, w.tone.b, 0.6)
    Column {
      anchors.centerIn: parent
      spacing: Style.space(2)
      Text { anchors.horizontalCenter: parent.horizontalCenter; text: w.g; color: w.tone; font.family: w.ff; font.pixelSize: Style.space(46) }
      Text { anchors.horizontalCenter: parent.horizontalCenter; text: w.temp; color: w.fg; font.family: w.ff; font.pixelSize: Style.space(36); font.bold: true }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        width: roundBox.width * 0.7; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
        text: w.n ? w.mod.words(w.n.code) : w.city
        color: Qt.darker(w.fg, 1.3)
        font.family: w.ff; font.pixelSize: Style.font.caption - 1
      }
    }
  }

  // --------------------------------------------------------------- tile
  Rectangle {
    id: tileBox
    visible: w.look === "tile"
    width: tileRow.implicitWidth + Style.space(36)
    height: Style.space(84)
    radius: DS.radius(w.deskStyle, Style.space(18))
    topLeftRadius: DS.corner(w.deskStyle, "tl", Style.space(18))
    topRightRadius: DS.corner(w.deskStyle, "tr", Style.space(18))
    bottomLeftRadius: DS.corner(w.deskStyle, "bl", Style.space(18))
    bottomRightRadius: DS.corner(w.deskStyle, "br", Style.space(18))
    color: w.fill
    border.width: 1
    border.color: Qt.rgba(w.tone.r, w.tone.g, w.tone.b, 0.35)
    Row {
      id: tileRow
      anchors.centerIn: parent
      spacing: Style.space(14)
      Text { anchors.verticalCenter: parent.verticalCenter; text: w.g; color: w.tone; font.family: w.ff; font.pixelSize: Style.space(40) }
      Text { anchors.verticalCenter: parent.verticalCenter; text: w.temp; color: w.fg; font.family: w.ff; font.pixelSize: Style.space(34); font.bold: true }
    }
  }
}
