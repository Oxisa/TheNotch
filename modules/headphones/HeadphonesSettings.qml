import QtQuick
import qs.Commons
import "../.."
import "../../vendor/soundhub" as SH
import "../../fonts"

// Settings → Bluetooth & devices → Headphones: the headphones' card on top
// (model, battery, connection); tabs Noise · Sound · Device.
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
  readonly property bool ok: !!(mod && mod.present)
  function feature(f) { return !!(st.features && st.features[f] === "available") }

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

  // not installed / not connected
  Card {
    visible: !page.ok
    SH.HubRow {
      icon: "\u{f02cb}"
      title: page.mod && !page.mod.installed ? page.t("Управление наушниками Sony не установлено", "Sony headphone control is not installed")
                                              : page.t("Наушники не подключены", "Headphones not connected")
      hint: page.mod && !page.mod.installed ? page.t("Соберу и поставлю для вашего пользователя, без пароля (пара минут): libmdr + mdrctld", "Builds and installs for your user, no password (a couple of minutes): libmdr + mdrctld")
                                            : page.t("Подключите WH-1000XM6 (или другие Sony с протоколом MDR v2) по Bluetooth", "Connect a WH-1000XM6 (or another MDR v2 Sony) over Bluetooth")
      fg: page.fg; fontFamily: page.ff
      SH.HubChip {
        visible: page.mod && !page.mod.installed
        icon: page.mod && page.mod.installing ? "\u{f051f}" : "\u{f01da}"
        label: page.mod && page.mod.installing ? page.t("Устанавливаю…", "Installing…") : page.t("Установить", "Install")
        on: true
        fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
        onClicked: if (!page.mod.installing) page.mod.install()
      }
    }
  }

  // the headphones' card
  Card {
    visible: page.ok
    Item {
      width: parent.width; height: Style.space(70)
      Item {
        id: ring
        width: Style.space(64); height: width
        anchors.verticalCenter: parent.verticalCenter
        Canvas {
          anchors.fill: parent
          property real p: Number(page.st.battery || 0)
          onPChanged: requestPaint()
          onPaint: {
            var ctx = getContext("2d"); ctx.reset()
            var c = width / 2, r = c - 4
            ctx.lineWidth = 5; ctx.lineCap = "round"
            ctx.strokeStyle = Qt.rgba(page.fg.r, page.fg.g, page.fg.b, 0.12); ctx.beginPath(); ctx.arc(c, c, r, 0, Math.PI * 2); ctx.stroke()
            ctx.strokeStyle = p <= 15 ? Color.urgent : page.accent; ctx.beginPath(); ctx.arc(c, c, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * p / 100); ctx.stroke()
          }
          Component.onCompleted: requestPaint()
        }
        Text { anchors.centerIn: parent; text: page.mod ? page.mod.modeIcon(page.mod.mode) : ""; color: page.accent; font.family: page.ff; font.pixelSize: Style.space(24) }
      }
      Column {
        anchors.left: ring.right; anchors.leftMargin: Style.space(14)
        anchors.verticalCenter: parent.verticalCenter
        Text { text: page.st.model || ""; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.body + 2; font.bold: true }
        Text {
          text: (page.st.battery !== undefined ? page.st.battery + "%" + (page.st.charging === "yes" ? page.t(" · заряжается", " · charging") : "") : "")
                + " · " + (page.mod ? page.mod.modeName(page.mod.mode) : "")
          color: Qt.darker(page.fg, 1.4); font.family: page.ff; font.pixelSize: Style.font.caption
        }
      }
    }
    Text { visible: !!(page.mod && page.mod.error); width: parent.width; wrapMode: Text.Wrap; text: page.mod ? page.mod.error : ""; color: Color.urgent; font.family: page.ff; font.pixelSize: Style.font.caption }
  }

  SettingsTabs {
    id: tabs
    visible: page.ok
    tabs: [{ id: "noise", label: page.t("Шумоподавление", "Noise"), icon: "\u{f02cb}" }, { id: "sound", label: page.t("Звук", "Sound"), icon: "\u{f0ea2}" },
           { id: "device", label: page.t("Устройство", "Device"), icon: "\u{f02cd}" }]
  }

  // ---------------------------------------------------------------- noise
  Card {
    visible: page.ok && tabs.current === "noise"
    Row {
      width: parent.width
      spacing: Style.space(8)
      Repeater {
        model: ["cancelling", "ambient", "off"]
        delegate: Rectangle {
          required property string modelData
          readonly property bool on: page.mod.mode === modelData
          width: (parent.width - Style.space(16)) / 3; height: Style.space(76)
          radius: SH.HubStyle.radius
          color: on ? SH.HubStyle.tint(page.accent, 0.30) : SH.HubStyle.tint(page.fg, mm.containsMouse ? 0.10 : 0.05)
          border.width: on ? 2 : 0; border.color: page.accent
          Column {
            anchors.centerIn: parent
            spacing: Style.space(4)
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: page.mod.modeIcon(modelData); color: parent.parent.on ? page.accent : page.fg; font.family: page.ff; font.pixelSize: Style.space(24) }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: page.mod.modeName(modelData); color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption; font.bold: parent.parent.on }
          }
          MouseArea { id: mm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.mod.cmd(["mode", modelData]) }
        }
      }
    }
    SH.HubRow {
      visible: page.mod && page.mod.mode === "ambient"
      title: page.t("Уровень окружения", "Ambient level"); fg: page.fg; fontFamily: page.ff
      SH.HubSlider {
        width: Style.space(200); minimum: 0; maximum: Number(page.st.ambient_level_max || 20); step: 1
        value: Number(page.st.ambient_level || 0)
        format: function(v) { return Math.round(v) }
        fillColor: page.accent; fontFamily: page.ff
        onReleased: function(v) { page.mod.cmd(["ambient", String(Math.round(v))]) }
      }
    }
  }

  // ---------------------------------------------------------------- sound
  Card {
    visible: page.ok && tabs.current === "sound"
    SH.HubRow {
      visible: page.feature("equalizer")
      title: page.t("Пресет эквалайзера", "Equalizer preset"); hint: page.t("XM6 принимает Heavy, Clear, Hard, Soft и свой", "The XM6 takes Heavy, Clear, Hard, Soft and custom"); fg: page.fg; fontFamily: page.ff
      SH.HubSelect {
        width: Style.space(200); showLabel: false
        options: ["custom", "heavy", "clear", "hard", "soft", "user-1", "user-2"].map(function(p) { return { value: p, label: p === "custom" ? page.t("Свой", "Custom") : p.charAt(0).toUpperCase() + p.slice(1) } })
        value: String(page.st.eq_preset || "custom")
        foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
        onChanged: function(v) { page.mod.cmd(["eq", v]) }
      }
    }
    // the headphones' own bands (10 on the XM6, ±6)
    Row {
      visible: page.feature("equalizer") && (page.st.eq_bands || []).length > 0
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Style.space(8)
      Repeater {
        model: page.st.eq_bands || []
        delegate: Column {
          required property int index
          required property var modelData
          spacing: Style.space(4)
          readonly property real lim: Number(page.st.eq_band_limit || 6)
          Item {
            width: Style.space(26); height: Style.space(130)
            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 4; height: parent.height; radius: 2; color: SH.HubStyle.tint(page.fg, 0.12) }
            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: parent.height / 2 - 1; width: 12; height: 2; color: SH.HubStyle.tint(page.fg, 0.3) }
            Rectangle {
              id: knob
              anchors.horizontalCenter: parent.horizontalCenter
              width: Style.space(16); height: width; radius: width / 2
              color: page.accent
              y: (1 - (modelData + lim) / (2 * lim)) * (parent.height - height)
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              function val(m) { return Math.round(lim - (m.y / height) * 2 * lim) }
              onPositionChanged: function(m) { if (pressed) knob.y = Math.max(0, Math.min(parent.height - knob.height, m.y - knob.height / 2)) }
              onReleased: function(m) {
                var v = Math.max(-lim, Math.min(lim, val(m))), b = (page.st.eq_bands || []).slice()
                b[index] = v
                page.mod.cmd(["bands", b.join(",")])
              }
            }
          }
          Text { anchors.horizontalCenter: parent.horizontalCenter; text: (modelData > 0 ? "+" : "") + modelData; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption - 2 }
        }
      }
    }
    SH.HubRow {
      visible: page.feature("dsee")
      title: "DSEE " + (page.st.dsee_type === "hx-ai" ? "HX AI" : page.st.dsee_type === "ultimate" ? "Ultimate" : "")
      hint: page.t("Восстанавливает детали сжатой музыки", "Restores detail in compressed music"); fg: page.fg; fontFamily: page.ff
      SH.HubSwitch { checked: page.st.dsee === true; fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.mod.cmd(["dsee", checked ? "off" : "on"]) }
    }
    SH.HubRow {
      title: page.t("Приоритет", "Priority"); hint: page.t("Качество — LDAC с высоким битрейтом; стабильность — меньше обрывов", "Quality is high-bitrate LDAC; stability drops fewer packets"); fg: page.fg; fontFamily: page.ff
      SH.HubSelect {
        width: Style.space(200); showLabel: false
        options: [{ value: "quality", label: page.t("Качество звука", "Sound quality") }, { value: "stability", label: page.t("Стабильность", "Stability") }]
        value: String(page.st.audio_priority || "quality")
        foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
        onChanged: function(v) { page.mod.cmd(["priority", v]) }
      }
    }
    SH.HubRow {
      visible: page.feature("listening_mode")
      title: page.t("Режим прослушивания", "Listening mode"); fg: page.fg; fontFamily: page.ff
      SH.HubSelect {
        width: Style.space(200); showLabel: false
        options: [{ value: "standard", label: page.t("Обычный", "Standard") }, { value: "background-music", label: page.t("Фоновая музыка", "Background music") },
                  { value: "cinema", label: page.t("Кино", "Cinema") }]
        value: String(page.st.listening || "standard")
        foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
        onChanged: function(v) { page.mod.cmd(["listening", v]) }
      }
    }
  }

  // --------------------------------------------------------------- device
  Card {
    visible: page.ok && tabs.current === "device"
    SH.HubRow {
      visible: page.feature("auto_pause")
      title: page.t("Пауза, когда снимаете", "Pause when taken off"); fg: page.fg; fontFamily: page.ff
      SH.HubSwitch { checked: page.st.auto_pause === true; fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.mod.cmd(["auto-pause", checked ? "off" : "on"]) }
    }
    SH.HubRow {
      visible: page.feature("auto_power_off")
      title: page.t("Автовыключение", "Auto power off"); fg: page.fg; fontFamily: page.ff
      SH.HubSelect {
        width: Style.space(200); showLabel: false
        options: (page.st.power_off_choices || ["when-removed", "never"]).map(function(c) {
          return { value: c, label: c === "when-removed" ? page.t("Когда снимаете", "When taken off") : c === "never" ? page.t("Никогда", "Never") : c + page.t(" мин", " min") } })
        value: String(page.st.power_off || "never")
        foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
        onChanged: function(v) { page.mod.cmd(["power-off", v]) }
      }
    }
    SH.HubRow {
      title: page.t("Два устройства сразу", "Multipoint"); hint: page.t("Подключение к компьютеру и телефону одновременно", "Connected to the computer and a phone at once"); fg: page.fg; fontFamily: page.ff
      SH.HubSwitch { checked: page.st.multipoint === true; fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.mod.cmd(["multipoint", checked ? "off" : "on"]) }
    }
    SH.HubRow {
      title: page.t("Сенсорная панель", "Touch panel"); fg: page.fg; fontFamily: page.ff
      SH.HubSwitch { checked: page.st.touch_panel === true; fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.mod.cmd(["touch-panel", checked ? "off" : "on"]) }
    }
    SH.HubCaption { text: page.t("Устройства наушников", "The headphones' devices"); icon: "\u{f00af}"; fg: page.fg; fontFamily: page.ff }
    Repeater {
      model: page.st.devices || []
      delegate: SH.HubRow {
        required property var modelData
        title: modelData.name + (modelData.mac === page.st.self_mac ? page.t(" (этот компьютер)", " (this computer)") : "")
        hint: modelData.connected ? (modelData.playback ? page.t("подключено · играет", "connected · playing") : page.t("подключено", "connected")) : page.t("не подключено", "not connected")
        fg: page.fg; fontFamily: page.ff
        SH.HubChip {
          visible: modelData.mac !== page.st.self_mac
          label: modelData.connected ? page.t("Отключить", "Disconnect") : page.t("Подключить", "Connect")
          h: Style.space(26)
          fg: page.fg; accent: page.accent; fontFamily: page.ff
          onClicked: page.mod.cmd(["device", modelData.connected ? "disconnect" : "connect", modelData.mac])
        }
      }
    }
    Row {
      spacing: Style.space(6)
      SH.HubChip { icon: "\u{f0450}"; label: page.t("Переподключить", "Reconnect"); fg: page.fg; accent: page.accent; fontFamily: page.ff; onClicked: page.mod.cmd(["reconnect"]) }
      SH.HubChip {
        property int confirm: 0
        icon: "\u{f0425}"; label: confirm ? page.t("Ещё раз — выключить", "Again to switch off") : page.t("Выключить наушники", "Switch off")
        fg: page.fg; accent: page.accent; fontFamily: page.ff
        onClicked: { if (++confirm >= 2) { page.mod.cmd(["shutdown"]); confirm = 0 } else offReset.restart() }
        Timer { id: offReset; interval: 3000; onTriggered: parent.confirm = 0 }
      }
    }
  }
}
