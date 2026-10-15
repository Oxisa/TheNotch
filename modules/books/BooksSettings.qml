import QtQuick
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// Books' Look tab in the layout editor, for the widget picked there (the
// main one or a copy): name, which book, folders, fonts, what to show, size;
// make a copy or delete this one.
Column {
  id: page
  property var mod: null
  spacing: Style.space(10)
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }
  readonly property string wid: mod ? mod.copies.picked : ""
  readonly property bool isCopy: !!mod && wid !== mod.moduleId
  readonly property var fd: mod ? mod.feed(wid) : null
  function put(values) { if (fd) fd.persist(values) }
  readonly property var fontsMod: mod && mod.notch ? mod.notch.moduleById("fonts") : null
  Component.onCompleted: if (fontsMod && !fontsMod.families.length) fontsMod.list()
  readonly property var fontOptions: [{ value: "default", label: t("Как у виджетов", "Widget font") },
                                      { value: "serif", label: "Noto Serif" },
                                      { value: "gothic", label: t("Готический (UnifrakturMaguntia)", "Blackletter (UnifrakturMaguntia)") }]
                                     .concat((fontsMod ? fontsMod.families : []).map(function(f) { return { value: f, label: f } }))

  component Caption: Text {
    color: Qt.darker(page.fg, 1.4); font.family: page.ff; font.pixelSize: Style.font.caption; font.bold: true
  }
  component Choice: Flow {
    id: ch
    property var items: []
    property string current: ""
    property string key: ""
    width: page.width
    spacing: Style.space(6)
    Repeater {
      model: ch.items
      delegate: SH.HubChip {
        required property var modelData
        icon: modelData.icon || ""; label: modelData.label
        on: ch.current === String(modelData.id)
        subtle: true
        h: Style.space(28)
        fg: page.fg; accent: page.accent; fontFamily: page.ff
        onClicked: { var v = {}; v[ch.key] = modelData.id; page.put(v) }
      }
    }
  }
  component Toggle: SH.HubRow {
    id: tg
    property string key: ""
    width: page.width
    fg: page.fg; fontFamily: page.ff
    SH.HubSwitch {
      checked: page.fd ? page.fd.cfg(tg.key, true) !== false : true
      fg: page.fg; accent: page.accent; ink: page.bgc
      onToggled: { var v = {}; v[tg.key] = !checked; page.put(v) }
    }
  }

  // ---- this widget: its name, a copy, delete
  SH.HubField {
    width: page.width
    icon: "\u{f0284}"
    placeholderText: page.mod ? page.mod.copies.titleOf(page.wid) : ""
    text: page.mod ? String(page.mod.copies.cfg(page.wid, "title", "")) : ""
    fg: page.fg; accent: page.accent; fontFamily: page.ff
    onEditingFinished: page.put({ title: text.trim() })
  }
  Flow {
    width: page.width
    spacing: Style.space(6)
    SH.HubChip {
      icon: "\u{f018f}"; label: page.t("Копия", "Duplicate")
      h: Style.space(28)
      fg: page.fg; accent: page.accent; fontFamily: page.ff
      onClicked: page.mod.notch.layoutPick = page.mod.copies.duplicate(page.wid)
    }
    SH.HubChip {
      visible: page.isCopy
      icon: "\u{f01b4}"; label: page.t("Удалить копию", "Delete this copy")
      danger: true; h: Style.space(28)
      fg: page.fg; accent: page.accent; fontFamily: page.ff
      onClicked: page.mod.copies.remove(page.wid)
    }
  }

  // ---- which book
  Caption { text: page.t("Какая книга", "Which book") }
  Choice {
    key: "mode"; current: page.fd ? page.fd.mode : "last"
    items: [{ id: "last", icon: "\u{f02da}", label: page.t("Последняя", "Last read") },
            { id: "random", icon: "\u{f049d}", label: page.t("Случайная", "Random") },
            { id: "cycle", icon: "\u{f0456}", label: page.t("По кругу", "Each in turn") }]
  }
  Caption { visible: !!page.fd && page.fd.mode !== "last"; text: page.t("Смена каждые", "Change every") }
  Choice {
    visible: !!page.fd && page.fd.mode !== "last"
    key: "interval"; current: page.fd ? String(page.fd.interval) : "60"
    items: [{ id: 15, label: "15 " + page.t("с", "s") }, { id: 60, label: "1 " + page.t("мин", "min") },
            { id: 300, label: "5 " + page.t("мин", "min") }, { id: 1800, label: "30 " + page.t("мин", "min") }, { id: 3600, label: "1 " + page.t("ч", "h") }]
  }

  // ---- folders
  Caption { text: page.t("Папки", "Folders") + (page.fd ? "  ·  " + page.fd.books.length + page.t(" книг", " books") : "") }
  Repeater {
    model: page.fd ? page.fd.folders : []
    delegate: Rectangle {
      required property string modelData
      width: page.width; height: Style.space(32)
      radius: SH.HubStyle.radius
      color: SH.HubStyle.tint(page.fg, 0.06)
      Text {
        x: Style.space(10); width: parent.width - Style.space(46)
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideMiddle
        text: modelData.replace(page.mod.home, "~")
        color: page.fg; font.family: page.ff; font.pixelSize: Style.font.body
      }
      SH.HubChip {
        anchors.right: parent.right; anchors.rightMargin: Style.space(4); anchors.verticalCenter: parent.verticalCenter
        icon: "\u{f0156}"; iconOnly: true; h: Style.space(24)
        fg: page.fg; accent: page.accent; fontFamily: page.ff
        onClicked: page.fd.removeFolder(modelData)
      }
    }
  }
  Row {
    spacing: Style.space(6)
    SH.HubChip {
      icon: "\u{f0257}"; label: page.t("Добавить папку…", "Add folder…")
      on: true; h: Style.space(28)
      fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
      onClicked: page.fd.pickFolders()
    }
    SH.HubField {
      width: page.width - Style.space(170); height: Style.space(28)
      placeholderText: page.t("или путь и Enter", "or a path, then Enter")
      fg: page.fg; accent: page.accent; fontFamily: page.ff
      onAccepted: { if (text.trim()) page.fd.addFolders([text]); text = "" }
    }
  }
  Toggle { key: "subfolders"; title: page.t("С подпапками", "Include subfolders") }
  Toggle { key: "history"; title: page.t("Книги из истории Foliate", "Books from Foliate's history"); hint: page.t("Всё, что открывали в Foliate, где бы файл ни лежал", "Everything opened in Foliate, wherever the file is") }

  // ---- look
  Caption { text: page.t("Шрифты", "Fonts") }
  SH.HubRow {
    width: page.width
    title: page.t("Название", "Title"); fg: page.fg; fontFamily: page.ff
    SH.HubSelect {
      width: Style.space(210); showLabel: false
      options: page.fontOptions
      value: page.fd ? page.fd.titleFont : "serif"
      foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
      onChanged: function(v) { page.put({ titleFont: v }) }
    }
  }
  SH.HubRow {
    width: page.width
    title: page.t("Автор", "Author"); fg: page.fg; fontFamily: page.ff
    SH.HubSelect {
      width: Style.space(210); showLabel: false
      options: page.fontOptions
      value: page.fd ? page.fd.authorFont : "default"
      foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
      onChanged: function(v) { page.put({ authorFont: v }) }
    }
  }
  Toggle { key: "author"; title: page.t("Автор под названием", "Author under the title") }
  Toggle { key: "progress"; title: page.t("Прогресс чтения", "Reading progress"); hint: page.t("Сколько прочитано в Foliate", "How far you are in Foliate") }
  SH.HubRow {
    width: page.width
    title: page.t("Размер", "Size"); fg: page.fg; fontFamily: page.ff
    controlWidth: Style.space(180)
    SH.HubSlider {
      width: Style.space(180)
      minimum: 240; maximum: 720; step: 20
      value: page.fd ? page.fd.size : 380
      format: function(v) { return Math.round(v) + " px" }
      fontFamily: page.ff
      onReleased: function(v) { page.put({ size: Math.round(v) }) }
    }
  }
  Text {
    width: page.width; wrapMode: Text.Wrap
    text: page.t("Клик — открыть книгу в Foliate; правый клик или колесо — другая книга. Поворот на 90° ставит обложку над текстом. «Копия» — ещё один виджет со своими папками.",
                 "Click opens the book in Foliate; right-click or the wheel shows another. Turned 90°, the cover stands above the text. Duplicate makes another widget with its own folders.")
    color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption - 1
  }
}
