import QtQuick
import qs.Commons
import "../.."
import "../../vendor/soundhub" as SH
import "../../fonts"

// Settings → Network & internet.
//   Basic     the connection (speed, latency), tunnels, Wi-Fi networks,
//             wired adapters
//   Details   addresses, DNS servers, saved connections, router ping
Column {
  id: page
  property var mod: null
  spacing: SH.HubStyle.gap
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }
  readonly property var p: mod ? mod.primary : null
  SettingsTabs {
    id: tabs
    // the Wi-Fi tab only while Wi-Fi is on
    tabs: [{ id: "conn", label: page.t("Подключение", "Connection"), icon: "\u{f059f}" }]
          .concat(page.mod && page.mod.wifiOn ? [{ id: "wifi", label: "Wi-Fi", icon: "\u{f0928}" }] : [])
          .concat([{ id: "wired", label: page.t("Кабель", "Wired"), icon: "\u{f0200}" }])
          .concat([{ id: "traffic", label: page.t("Трафик", "Traffic"), icon: "\u{f046a}" }, { id: "more", label: page.t("Подробно", "Details"), icon: "\u{f02fd}" }])
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
  component Info: Item {                         // label … value
    property string label: ""
    property string value: ""
    width: parent ? parent.width : 0
    height: Math.max(il.implicitHeight, iv.implicitHeight)
    visible: value !== ""
    Text { id: il; text: parent.label; color: Qt.darker(page.fg, 1.4); font.family: page.ff; font.pixelSize: Style.font.caption }
    Text {
      id: iv
      anchors.right: parent.right
      width: parent.width * 0.62
      horizontalAlignment: Text.AlignRight; wrapMode: Text.WrapAnywhere
      text: parent.value; color: page.fg
      font.family: page.ff; font.pixelSize: Style.font.caption
    }
  }

  // ------------------------------------------------------- connection
  Card {
    visible: page.tab === "conn"
    Item {
      width: parent.width; height: Style.space(64)
      Rectangle {
        id: hero
        width: Style.space(56); height: width; radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        color: SH.HubStyle.tint(page.mod && page.mod.online ? page.accent : page.fg, 0.18)
        Text { anchors.centerIn: parent; text: page.mod ? page.mod.glyph : ""; color: page.mod && page.mod.online ? page.accent : page.fg; font.family: page.ff; font.pixelSize: Style.space(28) }
      }
      Column {
        anchors.left: hero.right; anchors.leftMargin: Style.space(14)
        anchors.verticalCenter: parent.verticalCenter
        Text { text: page.mod ? page.mod.name : ""; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.body + 2; font.bold: true }
        Text {
          text: page.mod && page.mod.online ? page.t("Подключено", "Connected") + (page.mod.sub ? " · " + page.mod.sub : "")
                                              + (page.p && page.p.ip4 && page.p.ip4.length ? " · " + page.p.ip4[0].split("/")[0] : "")
                                            : page.t("Проверьте кабель или включите Wi-Fi", "Check the cable or turn Wi-Fi on")
          color: Qt.darker(page.fg, 1.4)
          font.family: page.ff; font.pixelSize: Style.font.caption
        }
      }
      Column {
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        Text { anchors.right: parent.right; text: "\u{f0045} " + (page.mod ? page.mod.rate(page.mod.down) : ""); color: page.accent; font.family: page.ff; font.pixelSize: Style.font.body; font.bold: true }
        Text { anchors.right: parent.right; text: "\u{f005d} " + (page.mod ? page.mod.rate(page.mod.up) : ""); color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption }
        Text {
          anchors.right: parent.right
          text: page.mod && page.mod.latency.ms ? page.t("задержка ", "latency ") + page.mod.latency.ms + page.t(" мс", " ms") : ""
          color: Qt.darker(page.fg, 1.5); font.family: page.ff; font.pixelSize: Style.font.caption - 1
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.mod.cmd(["ping"]) }
        }
      }
    }
    Text {
      visible: !!(page.mod && page.mod.error)
      width: parent.width; wrapMode: Text.Wrap
      text: page.mod ? page.mod.error : ""
      color: Color.urgent
      font.family: page.ff; font.pixelSize: Style.font.caption
    }
  }

  // Wi-Fi switched off: the switch lives here (the Wi-Fi tab shows once it's on)
  Card {
    visible: page.tab === "conn" && !!(page.mod && page.mod.st.hasWifi) && !page.mod.wifiOn
    SH.HubRow {
      width: parent.width
      icon: "\u{f05aa}"
      title: "Wi-Fi"; hint: page.t("Выключен — включите, чтобы увидеть сети", "Off — turn it on to see networks")
      fg: page.fg; fontFamily: page.ff
      SH.HubSwitch { checked: false; fg: page.fg; accent: page.accent; ink: page.bgc; onToggled: page.mod.setRadio(true) }
    }
  }

  // ---------------------------------------------------------- Wi-Fi
  Card {
    visible: page.tab === "wifi" && !!(page.mod && page.mod.st.hasWifi)
    SH.HubRow {
      title: "Wi-Fi"
      hint: page.mod && page.mod.wifiOn ? (page.mod.onWifi ? page.t("Подключено к ", "Connected to ") + page.mod.name : page.t("Включён", "On"))
                                              : page.t("Выключен", "Off")
      fg: page.fg; fontFamily: page.ff
      Row {
        spacing: Style.space(8)
        SH.HubChip {
          visible: page.mod && page.mod.wifiOn
          anchors.verticalCenter: parent.verticalCenter
          iconOnly: true
          icon: page.mod && page.mod.busy === "wifi" ? "\u{f051f}" : "\u{f0450}"
          label: page.t("Обновить список", "Rescan")
          fg: page.fg; accent: page.accent; fontFamily: page.ff
          onClicked: page.mod.cmd(["wifi", "rescan"])
        }
        SH.HubSwitch {
          anchors.verticalCenter: parent.verticalCenter
          checked: page.mod ? page.mod.wifiOn : false
          fg: page.fg; accent: page.accent; ink: page.bgc
          onToggled: page.mod.setRadio(!checked)
        }
      }
    }
    Repeater {
      model: page.mod && page.mod.wifiOn ? page.mod.networks : []
      delegate: Rectangle {
        id: net
        required property var modelData
        property bool open: false
        width: parent.width
        height: netCol.implicitHeight + Style.space(16)
        radius: SH.HubStyle.radiusSmall + Style.space(2)
        color: modelData.active ? SH.HubStyle.tint(page.accent, 0.16) : SH.HubStyle.tint(page.fg, nm.containsMouse || open ? 0.08 : 0.04)
        Column {
          id: netCol
          x: Style.space(12); y: Style.space(8)
          width: parent.width - Style.space(24)
          spacing: Style.space(8)
          Item {
            width: parent.width; height: Style.space(26)
            Row {
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(10)
              Text { anchors.verticalCenter: parent.verticalCenter; text: page.mod.wifiGlyph(net.modelData.signal); color: net.modelData.active ? page.accent : page.fg; font.family: page.ff; font.pixelSize: Style.space(18) }
              Text { anchors.verticalCenter: parent.verticalCenter; text: net.modelData.ssid; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.body; font.bold: net.modelData.active }
              Text { anchors.verticalCenter: parent.verticalCenter; visible: net.modelData.secure; text: "\u{f033e}"; color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption }
            }
            Row {
              anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(8)
              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: page.mod.busy === "connect:" + net.modelData.ssid ? page.t("подключаюсь…", "connecting…")
                      : net.modelData.active ? page.t("подключено", "connected") : net.modelData.saved ? page.t("сохранена", "saved") : ""
                color: net.modelData.active ? page.accent : Qt.darker(page.fg, 1.5)
                font.family: page.ff; font.pixelSize: Style.font.caption - 1
              }
              Text { anchors.verticalCenter: parent.verticalCenter; text: net.modelData.band + page.t(" ГГц", " GHz"); color: Qt.darker(page.fg, 1.7); font.family: page.ff; font.pixelSize: Style.font.caption - 2 }
            }
            MouseArea { id: nm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: net.open = !net.open }
          }
          // actions: connect (with a password when needed), disconnect, forget, QR
          Row {
            visible: net.open
            width: parent.width
            spacing: Style.space(6)
            SH.HubField {
              id: pass
              visible: net.modelData.secure && !net.modelData.saved && !net.modelData.active
              width: parent.width - goBtn.width - parent.spacing
              icon: "\u{f033e}"
              placeholderText: page.t("Пароль", "Password")
              fg: page.fg; accent: page.accent; fontFamily: page.ff
              onAccepted: { page.mod.connect(net.modelData.ssid, text); text = ""; net.open = false }
            }
            SH.HubChip {
              id: goBtn
              visible: !net.modelData.active
              icon: "\u{f0928}"; label: page.t("Подключить", "Connect")
              on: true
              fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
              onClicked: { page.mod.connect(net.modelData.ssid, pass.visible ? pass.text : ""); pass.text = ""; net.open = false }
            }
            SH.HubChip {
              visible: net.modelData.active
              icon: "\u{f05aa}"; label: page.t("Отключить", "Disconnect")
              fg: page.fg; accent: page.accent; fontFamily: page.ff
              onClicked: page.mod.cmd(["disconnect", page.p ? page.p.device : ""])
            }
            SH.HubChip {
              visible: net.modelData.saved
              icon: "\u{f0432}"; label: page.t("QR для телефона", "QR for a phone")
              fg: page.fg; accent: page.accent; fontFamily: page.ff
              onClicked: page.mod.cmd(["qr", net.modelData.ssid])
            }
            SH.HubChip {
              visible: net.modelData.saved
              icon: "\u{f01b4}"; label: page.t("Забыть", "Forget")
              fg: page.fg; accent: page.accent; fontFamily: page.ff
              onClicked: { page.mod.cmd(["forget", net.modelData.ssid]); net.open = false }
            }
          }
          // the QR code to join from a phone
          Row {
            visible: net.open && page.mod.qr !== null && page.mod.qr.ssid === net.modelData.ssid
            spacing: Style.space(14)
            Rectangle {
              width: Style.space(150); height: width; radius: Style.space(10); color: "white"
              Image { anchors.fill: parent; anchors.margins: Style.space(6); source: page.mod.qr ? page.mod.qr.url : ""; smooth: false; fillMode: Image.PreserveAspectFit }
            }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              width: Style.space(200); wrapMode: Text.Wrap
              text: page.t("Наведите камеру телефона — он подключится сам.", "Point a phone's camera here — it joins by itself.")
              color: Qt.darker(page.fg, 1.3); font.family: page.ff; font.pixelSize: Style.font.caption
            }
          }
        }
      }
    }
    Text {
      visible: page.mod && page.mod.wifiOn && page.mod.networks.length === 0
      text: page.t("Сетей не найдено. Нажмите «Обновить».", "No networks found. Press Rescan.")
      color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption
    }
  }

  // --------------------------------------------------------- wired
  Card {
    visible: page.tab === "wired"
    SH.HubCaption { text: page.t("Проводная сеть", "Wired"); icon: "\u{f0200}"; fg: page.fg; fontFamily: page.ff }
    Repeater {
      model: page.mod ? page.mod.st.devices.filter(function(d) { return d.type === "ethernet" }) : []
      delegate: SH.HubRow {
        required property var modelData
        readonly property bool on: modelData.state.indexOf("connected") === 0
        title: modelData.connection || modelData.device
        hint: modelData.device + " · " + (on ? page.t("подключено", "connected") : modelData.state === "unavailable" ? page.t("кабель не подключён", "no cable") : page.t("отключено", "disconnected"))
        fg: page.fg; fontFamily: page.ff
        SH.HubChip {
          visible: modelData.state !== "unavailable"
          label: on ? page.t("Отключить", "Disconnect") : page.t("Подключить", "Connect")
          on: !parent.on
          fg: page.fg; accent: page.accent; ink: page.bgc; fontFamily: page.ff
          onClicked: page.mod.cmd(on ? ["disconnect", modelData.device] : ["up", modelData.connection || modelData.device])
        }
      }
    }
  }

  // -------------------------------------------------------- details
  Card {
    visible: (page.tab === "more") && (page.p !== null)
    SH.HubCaption { text: page.t("Подробности подключения", "Connection details"); icon: "\u{f02fd}"; fg: page.fg; fontFamily: page.ff }
    Info { label: page.t("Устройство", "Device"); value: page.p ? page.p.device + (page.p.mtu ? " · MTU " + page.p.mtu : "") : "" }
    Info { label: "MAC"; value: page.p && page.p.mac ? page.p.mac : "" }
    Info { label: "IPv4"; value: page.p && page.p.ip4 ? page.p.ip4.join(", ") : "" }
    Info { label: "IPv6"; value: page.p && page.p.ip6 ? page.p.ip6.slice(0, 2).join(", ") : "" }
    Info { label: page.t("Шлюз", "Gateway"); value: page.p && page.p.gateway ? page.p.gateway + (page.mod.latency.router !== undefined && page.mod.latency.router !== null ? "  ·  " + page.mod.latency.router + page.t(" мс", " ms") : "") : "" }
    Info { label: "DNS"; value: page.p && page.p.dns ? page.p.dns.join(", ") : "" }
    Info { label: page.t("Частота и скорость", "Band and rate"); value: page.p && page.p.freq ? page.p.freq + " · " + page.p.rate : "" }
  }
  Card {
    visible: (page.tab === "more") && (page.p !== null)
    SH.HubRow {
      title: page.t("DNS-серверы", "DNS servers")
      hint: page.t("Для этого подключения; «Авто» — от роутера", "For this connection; Auto comes from the router")
      fg: page.fg; fontFamily: page.ff
      SH.HubSelect {
        width: Style.space(220); showLabel: false
        readonly property var presets: [{ value: "auto", label: page.t("Авто", "Auto") }, { value: "1.1.1.1,1.0.0.1", label: "Cloudflare" },
                                         { value: "8.8.8.8,8.8.4.4", label: "Google" }, { value: "9.9.9.9,149.112.112.112", label: "Quad9" },
                                         { value: "94.140.14.14,94.140.15.15", label: page.t("AdGuard (без рекламы)", "AdGuard (no ads)") }]
        readonly property string cur: page.p && page.p.dnsManual && page.p.dnsCustom ? page.p.dnsCustom.join(",") : "auto"
        options: presets.concat(presets.some(function(o) { return o.value === cur }) ? [] : [{ value: cur, label: cur }])
        value: cur
        foreground: page.fg; accent: page.accent; background: page.bgc; fontFamily: page.ff
        onChanged: function(v) { page.mod.cmd(["dns", page.p.connection, v]) }
      }
    }
    Row {
      width: parent.width
      spacing: Style.space(6)
      SH.HubField {
        id: dnsField
        width: parent.width - dnsGo.width - parent.spacing
        icon: "\u{f01d6}"
        placeholderText: page.t("Свои серверы через запятую", "Your own servers, comma-separated")
        fg: page.fg; accent: page.accent; fontFamily: page.ff
        onAccepted: dnsGo.clicked()
      }
      SH.HubChip {
        id: dnsGo
        label: page.t("Применить", "Apply")
        fg: page.fg; accent: page.accent; fontFamily: page.ff
        onClicked: if (dnsField.text.trim()) { page.mod.cmd(["dns", page.p.connection, dnsField.text.replace(/\s+/g, "")]); dnsField.text = "" }
      }
    }
  }
  Card {
    visible: (page.tab === "more")
    SH.HubCaption { text: page.t("Сохранённые подключения", "Saved connections"); icon: "\u{f0193}"; fg: page.fg; fontFamily: page.ff }
    Repeater {
      model: page.mod ? page.mod.saved : []
      delegate: SH.HubRow {
        required property var modelData
        title: modelData.name
        hint: (modelData.type === "wifi" ? "Wi-Fi" : modelData.type === "ethernet" ? page.t("Кабель", "Wired") : modelData.type)
              + (modelData.active ? page.t(" · активно", " · active") : "")
        fg: page.fg; fontFamily: page.ff
        SH.HubChip {
          visible: !modelData.active
          iconOnly: true; icon: "\u{f01b4}"; label: page.t("Удалить", "Delete")
          fg: page.fg; accent: page.accent; fontFamily: page.ff
          onClicked: page.mod.cmd(["forget", modelData.name])
        }
      }
    }
  }

  TrafficPage { visible: page.tab === "traffic"; width: page.width; mod: page.mod }
}
