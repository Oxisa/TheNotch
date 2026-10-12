import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Widgets
import qs.Commons
import "../.."
import "../../vendor/soundhub" as SH
import "../../fonts"

// Settings → Wallpaper: the current one large, then tabs — the theme's
// wallpapers, your folders, videos — as a grid; click one to set it.
Column {
  id: page
  property var mod: null
  spacing: SH.HubStyle.gap
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }
  readonly property var st: mod ? mod.st : ({})
  readonly property string current: st.video || st.background || ""
  property string folder: mod && mod.folders.length ? mod.folders[0] : ""

  // the current wallpaper
  ClippingRectangle {
    width: page.width; height: Math.round(page.width * 0.32)
    radius: SH.HubStyle.radius + Style.space(4)
    color: SH.HubStyle.tint(page.fg, 0.06)
    Image {
      anchors.fill: parent
      source: page.mod && page.current ? "file://" + (page.mod.isVideo(page.current) ? (page.mod.posters[page.current] || "") : page.current) : ""
      fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 1200
    }
    Rectangle {
      anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: Style.space(12)
      width: curLabel.implicitWidth + Style.space(20); height: Style.space(28); radius: height / 2
      color: Qt.rgba(0, 0, 0, 0.55)
      Text {
        id: curLabel; anchors.centerIn: parent
        text: (page.st.video ? "\u{f0567}  " : "\u{f02e9}  ") + (page.current ? page.current.split("/").pop() : "") + (page.st.theme ? "  ·  " + page.st.theme : "")
        color: "white"; font.family: page.ff; font.pixelSize: Style.font.caption
      }
    }
  }

  SettingsTabs {
    id: tabs
    tabs: [{ id: "theme", label: page.t("Тема", "Theme"), icon: "\u{f03d8}" }, { id: "mine", label: page.t("Мои", "Mine"), icon: "\u{f024b}" },
           { id: "video", label: page.t("Видео", "Video"), icon: "\u{f0567}" }]
  }

  // your folders: chips, plus a field to add one
  Flow {
    visible: tabs.current !== "theme"
    width: page.width
    spacing: Style.space(6)
    Repeater {
      model: page.mod ? page.mod.folders : []
      delegate: SH.HubChip {
        required property string modelData
        required property int index
        icon: "\u{f024b}"; label: modelData.split("/").pop()
        on: page.folder === modelData
        subtle: true; h: Style.space(28)
        fg: page.fg; accent: page.accent; fontFamily: page.ff
        onClicked: page.folder = modelData
      }
    }
    SH.HubField {
      width: Style.space(260)
      icon: "\u{f0415}"
      placeholderText: page.t("Добавить папку: ~/Pictures/…", "Add a folder: ~/Pictures/…")
      fg: page.fg; accent: page.accent; fontFamily: page.ff
      onAccepted: {
        var p = text.trim().replace(/^~/, Quickshell.env("HOME")).replace(/\/$/, "")
        if (p && page.mod.folders.indexOf(p) < 0) { page.mod.persist({ folders: page.mod.folders.concat([p]) }); page.folder = p; page.mod.cmd(["thumbs", p]) }
        text = ""
      }
    }
  }
  Row {
    visible: false
    spacing: Style.space(8)
    Text { anchors.verticalCenter: parent.verticalCenter; text: page.t("Видео-обоям нужен плагин Live Wallpaper", "Video wallpapers need the Live Wallpaper plugin"); color: Color.urgent; font.family: page.ff; font.pixelSize: Style.font.caption }
    SH.HubChip { label: page.t("Плагины Omarchy", "Omarchy plugins"); fg: page.fg; accent: page.accent; fontFamily: page.ff; onClicked: page.mod.notch.openSettings("plugins") }
  }

  FolderListModel {
    id: files
    folder: "file://" + (tabs.current === "theme" ? (page.st.themeDir || "") : page.folder)
    nameFilters: tabs.current === "video" ? ["*.mp4", "*.mkv", "*.webm", "*.mov", "*.m4v", "*.MP4"]
               : ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.PNG", "*.JPG", "*.JPEG"].concat(tabs.current === "theme" ? ["*.mp4", "*.webm", "*.mkv"] : [])
    showDirs: false
    sortField: FolderListModel.Time
  }
  // the theme's user folder too (videos you dropped for this theme)
  FolderListModel {
    id: themeUser
    folder: tabs.current === "theme" && page.st.userThemeDir ? "file://" + page.st.userThemeDir : ""
    nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.mp4", "*.webm", "*.mkv", "*.mov"]
    showDirs: false
  }

  component Thumb: ClippingRectangle {
    id: th
    property string path: ""
    readonly property bool video: page.mod ? page.mod.isVideo(path) : false
    readonly property bool on: page.current === path || (video && page.current.split("/").pop() === path.split("/").pop())
    width: (page.width - Style.space(24)) / 4; height: width * 0.6
    radius: Style.space(10)
    color: SH.HubStyle.tint(page.fg, 0.06)
    border.width: on || tm.containsMouse ? 2 : 0; border.color: page.accent
    Image {
      anchors.fill: parent
      source: th.video ? (page.mod.posters[th.path] ? "file://" + page.mod.posters[th.path] : "") : "file://" + th.path
      fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 320
    }
    Text { visible: th.video; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: Style.space(6); text: "\u{f0567}"; color: "white"; font.family: page.ff; font.pixelSize: Style.font.body; style: Text.Outline; styleColor: Qt.rgba(0, 0, 0, 0.6) }
    MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.mod.set(th.path) }
  }
  Flow {
    width: page.width
    spacing: Style.space(8)
    Repeater { model: themeUser; delegate: Thumb { required property string filePath; path: filePath } }
    Repeater {
      model: files
      delegate: Thumb { required property string filePath; required property int index; path: filePath; visible: index < 80 }
    }
  }
  Text {
    visible: files.count + themeUser.count === 0
    text: page.t("Здесь пусто", "Nothing here")
    color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption
  }
  Text {
    visible: files.count > 80
    text: page.t("Показаны 80 новых из ", "Showing the newest 80 of ") + files.count
    color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption - 1
  }
}
