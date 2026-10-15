import QtQuick
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// Gallery's Look tab in the layout editor, for the widget picked there (the
// main one or a copy): name, folders, look, caption, order, how long each
// file stays, videos, size; make a copy or delete this one.
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

  component Caption: Text {
    color: Qt.darker(page.fg, 1.4); font.family: page.ff; font.pixelSize: Style.font.caption; font.bold: true
  }
  // a row of chips, one of them chosen; `key` is the setting
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

  // ---- folders
  Caption { text: page.t("Папки", "Folders") + (page.fd ? "  ·  " + page.fd.files.length + page.t(" файлов", " files") : "") }
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
  SH.HubRow {
    width: page.width
    title: page.t("С подпапками", "Include subfolders"); fg: page.fg; fontFamily: page.ff
    SH.HubSwitch { checked: page.fd ? page.fd.subfolders : true; fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.put({ subfolders: !checked }) }
  }
  SH.HubRow {
    width: page.width
    title: page.t("Видео", "Videos"); hint: page.t("Играют без звука", "Play muted"); fg: page.fg; fontFamily: page.ff
    SH.HubSwitch { checked: page.fd ? page.fd.withVideos : true; fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.put({ videos: !checked }) }
  }
  SH.HubRow {
    width: page.width
    title: page.t("Папка и дата", "Folder and date")
    hint: page.t("Подпись под картинкой: папка и когда создан файл", "A caption: the folder and when the file was made")
    fg: page.fg; fontFamily: page.ff
    SH.HubSwitch { checked: page.fd ? page.fd.caption : false; fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.put({ caption: !checked }) }
  }

  // ---- look
  Caption { text: page.t("Вид", "Look") }
  Choice {
    key: "look"; current: page.fd ? page.fd.look : "carousel"
    items: [{ id: "carousel", icon: "\u{f0d58}", label: page.t("Карусель", "Carousel") },
            { id: "single", icon: "\u{f02e9}", label: page.t("Одна картинка", "Single") }]
  }
  Caption { visible: !!page.fd && page.fd.look === "single"; text: page.t("Эффект", "Effect") }
  Choice {
    visible: !!page.fd && page.fd.look === "single"
    key: "effect"; current: page.fd ? page.fd.effect : "kenburns"
    items: [{ id: "kenburns", label: page.t("Наезд камеры", "Ken Burns") },
            { id: "fade", label: page.t("Растворение", "Fade") },
            { id: "slide", label: page.t("Сдвиг", "Slide") }]
  }
  Caption { text: page.t("Порядок", "Order") }
  Choice {
    key: "order"; current: page.fd ? (page.fd.shuffle ? "shuffle" : "seq") : "shuffle"
    items: [{ id: "shuffle", icon: "\u{f049d}", label: page.t("Вперемешку", "Shuffled") },
            { id: "seq", icon: "\u{f0456}", label: page.t("По порядку", "In order") }]
  }
  Caption { text: page.t("Смена каждые", "Change every") }
  Choice {
    key: "interval"; current: page.fd ? String(page.fd.interval) : "10"
    items: [{ id: 5, label: "5 " + page.t("с", "s") }, { id: 10, label: "10 " + page.t("с", "s") }, { id: 30, label: "30 " + page.t("с", "s") },
            { id: 60, label: "1 " + page.t("мин", "min") }, { id: 300, label: "5 " + page.t("мин", "min") }]
  }
  SH.HubRow {
    width: page.width
    title: page.t("Размер", "Size"); fg: page.fg; fontFamily: page.ff
    controlWidth: Style.space(180)
    SH.HubSlider {
      width: Style.space(180)
      minimum: 240; maximum: 960; step: 20
      value: page.fd ? page.fd.size : 480
      format: function(v) { return Math.round(v) + " px" }
      fontFamily: page.ff
      onReleased: function(v) { page.put({ size: Math.round(v) }) }
    }
  }
  Text {
    width: page.width; wrapMode: Text.Wrap
    text: page.t("Клик по картинке — папка с файлом и сам файл; правый клик или колесо — следующая; по краям карусели — назад и вперёд. «Копия» — ещё одна галерея со своими папками.",
                 "Click the picture to show it in its folder and open it; right-click or the wheel steps; the carousel's sides go back and forth. Duplicate makes another gallery with its own folders.")
    color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption - 1
  }
}
