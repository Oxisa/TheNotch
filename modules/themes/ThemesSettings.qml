import QtQuick
import Quickshell.Widgets
import Qt.labs.folderlistmodel
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// Settings → Personalisation → Themes: a grid of theme cards (preview,
// colours, the current one ringed), the matching-wallpaper switch, and a
// new theme from a colour.
Column {
  id: page
  property var mod: null
  spacing: SH.HubStyle.gap
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }
  readonly property string cur: mod && mod.current ? mod.current.name || "" : ""

  SH.HubCard {
    width: page.width
    height: opts.implicitHeight + SH.HubStyle.pad * 2
    fg: page.fg; accent: page.accent
    Column {
      id: opts
      x: SH.HubStyle.pad; y: SH.HubStyle.pad
      width: parent.width - SH.HubStyle.pad * 2
      spacing: Style.space(6)
      SH.HubRow {
        width: parent.width
        title: page.t("Обои в тон теме", "Wallpaper to match")
        hint: page.mod && page.mod.haveEngine ? page.t("Вместе с темой ставятся обои из «", "The theme comes with a wallpaper from “") + (page.mod ? page.mod.library.split("/").pop() : "") + page.t("» с похожими цветами", "” in similar colours")
                                             : page.t("Нужен плагин Omapalette (включать не обязательно)", "Needs the Omapalette plugin (doesn't have to be on)")
        fg: page.fg; fontFamily: page.ff
        SH.HubSwitch { checked: !!(page.mod && page.mod.matchWallpaper); fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.mod.persist({ matchWallpaper: !page.mod.matchWallpaper }) }
      }
      SH.HubRow {
        width: parent.width
        visible: !!(page.mod && page.mod.haveEngine)
        title: page.t("Проанализировать обои", "Read the wallpapers' colours")
        hint: page.t("Один раз после новых картинок; ~25 с на 1000 штук", "Once after new pictures; ~25 s per 1000")
        fg: page.fg; fontFamily: page.ff
        SH.HubChip { icon: page.mod && page.mod.busy === "index" ? "\u{f0450}" : "\u{f0e09}"; label: page.mod && page.mod.busy === "index" ? page.t("Читаю…", "Reading…") : page.t("Начать", "Start"); fg: page.fg; accent: page.accent; fontFamily: page.ff; onClicked: page.mod.index() }
      }
      // a theme from one colour
      SH.HubRow {
        width: parent.width
        visible: !!(page.mod && page.mod.haveEngine)
        title: page.t("Новая тема из цвета", "A new theme from a colour")
        hint: page.t("Например #d19ea7; можно светлую", "e.g. #d19ea7; light if you like")
        fg: page.fg; fontFamily: page.ff
        Row {
          spacing: Style.space(6)
          Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Style.space(22); height: width; radius: width / 2; color: /^#[0-9a-fA-F]{6}$/.test(hex.text) ? hex.text : "transparent"; border.width: 1; border.color: SH.HubStyle.tint(page.fg, 0.3) }
          SH.HubField { id: hex; width: Style.space(110); placeholderText: "#rrggbb"; fg: page.fg; accent: page.accent; fontFamily: page.ff }
          SH.HubChip { id: light; property bool on2: false; label: page.t("Светлая", "Light"); on: on2; subtle: true; fg: page.fg; accent: page.accent; fontFamily: page.ff; onClicked: on2 = !on2 }
          SH.HubChip {
            icon: page.mod && page.mod.busy.indexOf("from-color") === 0 ? "\u{f0450}" : "\u{f0415}"; label: page.t("Создать", "Create"); on: true
            fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
            onClicked: if (/^#[0-9a-fA-F]{6}$/.test(hex.text)) page.mod.fromColor(hex.text, light.on2)
          }
        }
      }
    }
  }

  Flow {
    width: page.width
    spacing: Style.space(10)
    Repeater {
      model: page.mod ? page.mod.themes : []
      delegate: Rectangle {
        id: card
        required property var modelData
        readonly property bool on: page.cur === modelData.name
        readonly property bool working: page.mod.busy.indexOf(":" + modelData.name) > 0
        width: (page.width - Style.space(20)) / 3; height: width * 0.62 + Style.space(44)
        radius: SH.HubStyle.radius + Style.space(2)
        color: modelData.background
        border.width: on ? 3 : cm.containsMouse ? 2 : 1
        border.color: on || cm.containsMouse ? page.accent : SH.HubStyle.tint(page.fg, 0.12)
        ClippingRectangle {
          x: Style.space(6); y: Style.space(6); width: parent.width - Style.space(12); height: card.width * 0.62 - Style.space(6)
          radius: SH.HubStyle.radius
          color: "transparent"
          // its preview, or else its first wallpaper
          FolderListModel { id: bgs; folder: "file://" + card.modelData.path + "/backgrounds"; nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]; showDirs: false }
          Image {
            id: prev
            anchors.fill: parent; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 420
            source: "file://" + card.modelData.path + "/preview.png"
            onStatusChanged: if (status === Image.Error && bgs.count > 0) source = "file://" + bgs.get(0, "filePath")
          }
          Connections { target: bgs; function onCountChanged() { if (prev.status === Image.Error && bgs.count > 0) prev.source = "file://" + bgs.get(0, "filePath") } }
          Rectangle { visible: card.working; anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.5); Text { anchors.centerIn: parent; text: page.t("Ставлю…", "Applying…"); color: "white"; font.family: page.ff; font.pixelSize: Style.font.caption } }
        }
        Item {
          x: Style.space(10); y: card.width * 0.62 + Style.space(4)
          width: parent.width - Style.space(20); height: Style.space(32)
          Text { anchors.verticalCenter: parent.verticalCenter; text: card.modelData.label.replace(/\b\w/g, function(c) { return c.toUpperCase() }); color: card.modelData.foreground; font.family: page.ff; font.pixelSize: Style.font.caption + 1; font.bold: true }
          Row {
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            Repeater { model: card.modelData.swatches; delegate: Rectangle { required property string modelData; width: Style.space(10); height: width; radius: width / 2; color: modelData } }
          }
        }
        MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (!card.on) page.mod.apply(card.modelData.name) }
      }
    }
  }
}
