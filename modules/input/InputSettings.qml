import QtQuick
import qs.Commons
import "../.."
import "../../vendor/soundhub" as SH
import "../../fonts"

// Settings → Input.
// Everything on one page: pointer speed, scrolling direction, key repeat, layouts, the key bindings with a search; also acceleration, touchpad details, connected pointing devices .
Column {
  id: page
  property var mod: null
  readonly property bool full: true            // everything shown: the extra bits were too few for an Advanced mode
  spacing: SH.HubStyle.gap
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }
  readonly property var v: mod ? mod.st.values : ({})
  property string filter: ""
  SettingsTabs {
    id: tabs
    tabs: [{ id: "mouse", label: page.t("Мышь и тачпад", "Mouse & touchpad"), icon: "\u{f037d}" }, { id: "kb", label: page.t("Клавиатура", "Keyboard"), icon: "\u{f030c}" },
           { id: "keys", label: page.t("Горячие клавиши", "Key bindings"), icon: "\u{f030c}" },
           { id: "cursor", label: page.t("Курсор", "Cursor"), icon: "\u{f01bf}" }]
  }
  readonly property string tab: tabs.current


  component Card: SH.HubCard {
    width: page.width
    height: inner.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    default property alias content: inner.data
    Column {
      id: inner
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      spacing: Style.space(10)
    }
  }
  component Toggle: SH.HubRow {
    property string key: ""
    fg: page.fg; fontFamily: page.ff
    SH.HubSwitch { checked: !!page.v[parent.key]; fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.mod.set(parent.key, !checked) }
  }

  Card {
    visible: page.tab === "mouse"
    SH.HubCaption { text: page.t("Мышь", "Mouse"); icon: "\u{f037d}"; fg: page.fg; fontFamily: page.ff }
    SH.HubRow {
      title: page.t("Скорость указателя", "Pointer speed"); fg: page.fg; fontFamily: page.ff
      SH.HubSlider {
        width: Style.space(220); minimum: -1; maximum: 1; step: 0.05
        value: Number(page.v.sensitivity || 0)
        format: function(x) { return (x > 0 ? "+" : "") + x.toFixed(2) }
        fillColor: page.accent; fontFamily: page.ff
        onReleased: function(x) { page.mod.set("sensitivity", Math.round(x * 100) / 100) }
      }
    }
    Toggle { key: "natural_scroll"; title: page.t("Естественная прокрутка", "Natural scrolling"); hint: page.t("Содержимое едет за пальцем, как на телефоне", "Content follows your finger, like on a phone") }
    SH.HubRow {
      visible: page.full
      title: page.t("Ускорение", "Acceleration"); hint: page.t("«Ровное» — для игр и точной работы", "Flat is for games and precise work"); fg: page.fg; fontFamily: page.ff
      SH.HubSelect {
        width: Style.space(220); showLabel: false
        options: [{ value: "adaptive", label: page.t("Адаптивное", "Adaptive") }, { value: "flat", label: page.t("Ровное", "Flat") }]
        value: String(page.v.accel_profile || "adaptive")
        foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
        onChanged: function(x) { page.mod.set("accel_profile", x) }
      }
    }
    Text {
      visible: page.full && page.mod && page.mod.st.mice.length > 0
      width: parent.width; wrapMode: Text.Wrap
      text: page.t("Подключены: ", "Connected: ") + (page.mod ? page.mod.st.mice.join(", ") : "")
      color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption - 1
    }
  }

  Card {
    visible: (page.tab === "mouse") && (page.mod && (page.mod.st.touchpad || page.full))
    SH.HubCaption { text: page.t("Тачпад", "Touchpad"); icon: "\u{f073c}"; fg: page.fg; fontFamily: page.ff }
    Toggle { key: "touchpad.natural_scroll"; title: page.t("Естественная прокрутка", "Natural scrolling") }
    Toggle { key: "touchpad.tap-to-click"; title: page.t("Нажатие касанием", "Tap to click") }
    Toggle { visible: page.full; key: "touchpad.disable_while_typing"; title: page.t("Выключать при наборе текста", "Off while typing") }
  }

  Card {
    visible: page.tab === "kb"
    SH.HubCaption { text: page.t("Клавиатура", "Keyboard"); icon: "\u{f030c}"; fg: page.fg; fontFamily: page.ff }
    SH.HubRow {
      title: page.t("Раскладки", "Layouts")
      hint: page.t("Сейчас: ", "Now: ") + (page.mod ? page.mod.st.activeLayout : "") + page.t(" · первая — по умолчанию · переключение Alt+Shift", " · the first is the default · Alt+Shift switches")
      fg: page.fg; fontFamily: page.ff
    }
    Flow {
      width: parent.width
      spacing: Style.space(6)
      Repeater {
        model: page.mod ? page.mod.st.layouts : []
        delegate: Rectangle {
          required property string modelData
          required property int index
          width: lr.implicitWidth + Style.space(14); height: Style.space(30); radius: height / 2
          color: SH.HubStyle.tint(page.accent, index === 0 ? 0.32 : 0.18)
          Row {
            id: lr
            anchors.centerIn: parent
            spacing: Style.space(6)
            Text {
              visible: index > 0
              anchors.verticalCenter: parent.verticalCenter
              text: "\u{f0141}"; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.body
              MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: page.mod.moveLayout(index, -1) }
            }
            Text { anchors.verticalCenter: parent.verticalCenter; text: page.mod.layoutName(modelData); color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption + 1; font.bold: true }
            Text {
              visible: page.mod.st.layouts.length > 1
              anchors.verticalCenter: parent.verticalCenter
              text: "󰅖"; color: Qt.darker(page.fg, 1.4); font.family: page.ff; font.pixelSize: Style.font.caption
              MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: page.mod.removeLayout(index) }
            }
          }
        }
      }
    }
    SH.HubField {
      id: layoutSearch
      width: parent.width
      icon: "\u{f0415}"
      placeholderText: page.t("Добавить раскладку: немецкая, uk, español…", "Add a layout: German, uk, español…")
      fg: page.fg; accent: page.accent; fontFamily: page.ff
      onTextEdited: if (page.mod) page.mod.loadAll()
    }
    Flow {
      visible: layoutSearch.text.trim().length > 0
      width: parent.width
      spacing: Style.space(6)
      Repeater {
        model: {
          var q = layoutSearch.text.trim().toLowerCase(), all = page.mod ? page.mod.allLayouts : []
          return q ? all.filter(function(l) { return l.code.indexOf(q) === 0 || l.name.toLowerCase().indexOf(q) >= 0 }).slice(0, 12) : []
        }
        delegate: SH.HubChip {
          required property var modelData
          icon: "\u{f0415}"; label: modelData.name + " (" + modelData.code + ")"
          subtle: true
          h: Style.space(26)
          fg: page.fg; accent: page.accent; fontFamily: page.ff
          onClicked: { page.mod.addLayout(modelData.code); layoutSearch.text = "" }
        }
      }
    }
    SH.HubRow {
      title: page.t("Задержка повтора", "Repeat delay"); hint: page.t("Сколько держать клавишу до повтора", "How long to hold a key before it repeats"); fg: page.fg; fontFamily: page.ff
      SH.HubSlider {
        width: Style.space(220); minimum: 150; maximum: 800; step: 10
        value: Number(page.v.repeat_delay || 600)
        format: function(x) { return Math.round(x) + page.t(" мс", " ms") }
        fillColor: page.accent; fontFamily: page.ff
        onReleased: function(x) { page.mod.set("repeat_delay", Math.round(x)) }
      }
    }
    SH.HubRow {
      title: page.t("Скорость повтора", "Repeat rate"); fg: page.fg; fontFamily: page.ff
      SH.HubSlider {
        width: Style.space(220); minimum: 10; maximum: 80; step: 1
        value: Number(page.v.repeat_rate || 25)
        format: function(x) { return Math.round(x) + page.t(" в секунду", "/s") }
        fillColor: page.accent; fontFamily: page.ff
        onReleased: function(x) { page.mod.set("repeat_rate", Math.round(x)) }
      }
    }
  }

  Card {
    visible: page.tab === "keys"
    SH.HubCaption { text: page.t("Горячие клавиши", "Key bindings") + (page.mod ? " · " + page.mod.st.binds.length : ""); icon: "\u{f030c}"; fg: page.fg; fontFamily: page.ff }
    KeyboardMap {
      width: parent.width
      binds: page.mod ? page.mod.st.binds : []
      onPick: function(combo) { search.text = combo; page.filter = combo.toLowerCase() }
    }
    SH.HubField {
      id: search
      width: parent.width
      icon: "󰍉"
      placeholderText: page.t("Найти: громкость, скриншот, SUPER + …", "Find: volume, screenshot, SUPER + …")
      fg: page.fg; accent: page.accent; fontFamily: page.ff
      onTextEdited: page.filter = text.toLowerCase()
    }
    Repeater {
      model: (page.mod ? page.mod.st.binds : []).filter(function(b) {
        return !page.filter || b.what.toLowerCase().indexOf(page.filter) >= 0 || b.keys.toLowerCase().indexOf(page.filter) >= 0
      }).slice(0, page.filter ? 60 : 25)
      delegate: Item {
        required property var modelData
        width: parent.width; height: Style.space(26)
        Text { anchors.verticalCenter: parent.verticalCenter; width: parent.width * 0.6; elide: Text.ElideRight; text: modelData.what; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption + 1 }
        Rectangle {
          anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
          width: kt.implicitWidth + Style.space(14); height: Style.space(22); radius: Style.space(6)
          color: SH.HubStyle.tint(page.fg, 0.08)
          Text { id: kt; anchors.centerIn: parent; text: modelData.keys; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption - 1; font.bold: true }
        }
      }
    }
  }

  // ---------------------------------------------------------------- cursor
  readonly property var cur: mod ? mod.cursors.current || ({}) : ({})
  readonly property string curMode: cur.theme === "Omarchy-Accent" ? "plugin" : (cur.theme === "Adwaita" || cur.theme === "default" || !cur.theme) ? "standard" : "own"
  Card {
    visible: page.tab === "cursor"
    SH.HubRow {
      icon: "\u{f01bf}"
      title: page.t("Курсор", "Cursor")
      hint: page.t("Сейчас: ", "Now: ") + (page.cur.theme || "Adwaita") + " · " + (page.cur.size || 24) + " px"
      fg: page.fg; fontFamily: page.ff
    }
    Row {
      spacing: Style.space(6)
      Repeater {
        model: [{ id: "standard", label: page.t("Стандартный", "Standard"), theme: "Adwaita" },
                { id: "plugin", label: page.t("Плагин Cursor Accent", "Cursor Accent plugin"), theme: "Omarchy-Accent" },
                { id: "own", label: page.t("Свой", "Your own"), theme: "" }]
        delegate: SH.HubChip {
          required property var modelData
          label: modelData.label
          on: page.curMode === modelData.id
          h: Style.space(30)
          fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
          onClicked: if (modelData.theme) page.mod.cursorCmd(["apply", modelData.theme, String(page.cur.size || 24)])
        }
      }
    }
    Text {
      visible: page.curMode === "plugin"
      width: parent.width; wrapMode: Text.Wrap
      text: page.t("Cursor Accent перекрашивает курсор под цвет темы. Выбор другой темы выключит плагин, «Плагин» — включит обратно.",
                   "Cursor Accent recolours the pointer to the theme. Picking another theme switches the plugin off; “Plugin” switches it back on.")
      color: Qt.darker(page.fg, 1.5); font.family: page.ff; font.pixelSize: Style.font.caption - 1
    }
    SH.HubRow {
      title: page.t("Размер", "Size"); fg: page.fg; fontFamily: page.ff
      SH.HubSlider {
        width: Style.space(200); minimum: 16; maximum: 96; step: 4
        value: Number(page.cur.size || 24)
        format: function(v) { return Math.round(v) + " px" }
        fillColor: page.accent; fontFamily: page.ff
        onReleased: function(v) { page.mod.cursorCmd(["apply", page.cur.theme || "Adwaita", String(Math.round(v))]) }
      }
    }
    Text {
      visible: !!(page.mod && page.mod.cursorError)
      width: parent.width; wrapMode: Text.Wrap
      text: page.mod ? page.mod.cursorError : ""
      color: Color.urgent; font.family: page.ff; font.pixelSize: Style.font.caption
    }
  }
  Card {
    visible: page.tab === "cursor"
    SH.HubCaption { text: page.t("Темы курсоров", "Cursor themes"); icon: "\u{f02e9}"; fg: page.fg; fontFamily: page.ff }
    Flow {
      width: parent.width
      spacing: Style.space(8)
      Repeater {
        model: page.mod ? page.mod.cursors.themes || [] : []
        delegate: Rectangle {
          id: ct
          required property var modelData
          readonly property bool on: page.cur.theme === modelData.name
          width: Style.space(108); height: Style.space(124)
          radius: SH.HubStyle.radius
          color: on ? SH.HubStyle.tint(page.accent, 0.25) : SH.HubStyle.tint(page.fg, ctm.containsMouse ? 0.10 : 0.05)
          border.width: on ? 2 : 0; border.color: page.accent
          Image {
            anchors.horizontalCenter: parent.horizontalCenter
            y: Style.space(12)
            width: Style.space(56); height: width
            source: ct.modelData.preview ? "file://" + ct.modelData.preview : ""
            fillMode: Image.PreserveAspectFit
            smooth: false                                     // pixel-art cursors stay crisp
          }
          Column {
            anchors.bottom: parent.bottom; anchors.bottomMargin: Style.space(8)
            anchors.horizontalCenter: parent.horizontalCenter
            Text { anchors.horizontalCenter: parent.horizontalCenter; width: ct.width - Style.space(10); horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                   text: ct.modelData.name; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption - 1; font.bold: ct.on }
            Text { anchors.horizontalCenter: parent.horizontalCenter
                   text: ({ system: page.t("системная", "system"), user: page.t("ваша", "yours"), plugin: page.t("плагин", "plugin"), imported: page.t("из архива", "from a zip") })[ct.modelData.kind] || ""
                   color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption - 3 }
          }
          MouseArea { id: ctm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                      onClicked: page.mod.cursorCmd(["apply", ct.modelData.name, String(page.cur.size || 24)]) }
          Text {
            visible: ct.modelData.kind === "imported" && ctm.containsMouse
            anchors.right: parent.right; anchors.top: parent.top; anchors.margins: Style.space(6)
            text: "󰅖"; color: Qt.darker(page.fg, 1.3); font.family: page.ff; font.pixelSize: Style.font.caption
            MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: page.mod.cursorCmd(["delete", ct.modelData.name]) }
          }
        }
      }
    }
  }
  Card {
    visible: page.tab === "cursor"
    SH.HubCaption { text: page.t("Скачанные наборы", "Downloaded packs"); icon: "\u{f01da}"; fg: page.fg; fontFamily: page.ff }
    Text {
      width: parent.width; wrapMode: Text.Wrap
      text: page.t("Архивы с курсорами Windows (.ani, .cur) из «Загрузок» — превращаются в тему Linux с анимацией. Только для себя: многие авторы запрещают выкладывать их дальше.",
                   "Windows cursor packs (.ani, .cur) from Downloads become a Linux theme, animations kept. For yourself only: many authors forbid re-sharing them.")
      color: Qt.darker(page.fg, 1.5); font.family: page.ff; font.pixelSize: Style.font.caption - 1
    }
    Repeater {
      model: page.mod ? page.mod.packs : []
      delegate: SH.HubRow {
        required property var modelData
        title: modelData.name
        hint: modelData.cursors + page.t(" курсоров", " cursors") + (modelData.imported ? page.t(" · уже установлен", " · installed") : "")
        fg: page.fg; fontFamily: page.ff
        SH.HubChip {
          icon: page.mod.cursorBusy.indexOf(modelData.zip) >= 0 ? "\u{f051f}" : "\u{f01da}"
          label: modelData.imported ? page.t("Переустановить", "Reinstall") : page.t("Установить", "Install")
          on: !modelData.imported
          fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
          onClicked: page.mod.cursorCmd(["import", modelData.zip])
        }
      }
    }
    SH.HubChip {
      icon: "\u{f0256}"; label: page.t("Другой архив…", "Another zip…")
      fg: page.fg; accent: page.accent; fontFamily: page.ff
      onClicked: page.mod.importZip()
    }
  }
}
