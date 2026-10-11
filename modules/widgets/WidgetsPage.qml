import QtQuick
import qs.Commons
import "../../../osia.soundhub" as SH

Column {
  id: page
  property var notch: null
  spacing: SH.HubStyle.gap

  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Style.font.family
  readonly property bool ru: notch && notch.lang === "ru"

  // the layout editor: drag the widgets around on the desktop itself
  SH.HubCard {
    width: parent.width
    height: arrangeRow.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    SH.HubRow {
      id: arrangeRow
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      title: page.ru ? "Раскладка на рабочем столе" : "Desktop layout"
      hint: page.ru ? "Сетка поверх рабочего стола: тяните виджеты, они липнут к сетке, краям и друг к другу; на каждом мониторе своя раскладка"
                    : "A grid over the desktop: drag the widgets, they stick to the grid, the edges and each other; each monitor has its own layout"
      fg: page.fg; fontFamily: page.ff
      SH.HubChip {
        icon: "\u{f072c}"
        label: page.ru ? "Расставить" : "Arrange"
        on: true
        fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
        onClicked: page.notch.editLayout(true)
      }
    }
  }

  // every widget's settings (its look, the shared Style, place) live in the
  // layout editor only — click a widget there; nothing is repeated here
  SH.HubCard {
    width: parent.width
    height: tips.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    Column {
      id: tips
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      spacing: Style.space(6)
      Repeater {
        model: page.ru ? ["\u{f072c}  Корзина виджетов — все виджеты; перетащите на стол, чтобы поставить, со стола в корзину — чтобы убрать",
                          "\u{f03d8}  Клик по виджету — панель рядом: «Вид» (его настройки), «Оформление» (фон, скругление, рамка, тень, цвета), «Место» (масштаб)",
                          "\u{f0416}  Свои виджеты: текст с подстановками, вывод команды, картинка, заметка",
                          "\u{f0467}  Поворот на 90° перестраивает виджет вертикально; замок закрепляет"]
                       : ["\u{f072c}  The widget tray holds every widget; drag one onto the desktop to place it, back to the tray to remove it",
                          "\u{f03d8}  Click a widget for its panel: Look (its settings), Style (background, corners, border, shadow, colours), Place (scale)",
                          "\u{f0416}  Your own widgets: text with fields, a command's output, a picture, a note",
                          "\u{f0467}  Turning by 90° switches to a vertical layout; the lock pins a widget"]
        delegate: Text {
          required property string modelData
          width: tips.width; wrapMode: Text.Wrap
          text: modelData
          color: Qt.darker(page.fg, 1.2); font.family: page.ff; font.pixelSize: Style.font.caption + 1
        }
      }
    }
  }
}
