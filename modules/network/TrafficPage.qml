import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Commons
import "../../vendor/soundhub" as SH
import "../../fonts"

// Settings → Network → Traffic: where the traffic goes — the way out
// (which link, the public address, its city and owner), whether names
// (DNS) leave by another link, which apps talk over which link, what
// listens for connections, Tailscale. The facts come from Bananet's
// collector (banan.bananet, MIT, its collect.py, run as is — the plugin
// itself can stay off). Shown only: nothing here switches a link.
Column {
  id: tp
  property var mod: null
  spacing: SH.HubStyle.gap
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }

  readonly property string collector: decodeURIComponent(Qt.resolvedUrl("../../vendor/bananet/collect.py").toString().replace(/^file:\/\//, ""))
  property bool have: true
  FileView { path: tp.collector; printErrors: false; onLoadFailed: tp.have = false; onLoaded: tp.have = true }
  property var d: ({})
  property bool loading: false
  Process {
    id: col
    command: ["python3", "-I", tp.collector]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: { try { tp.d = JSON.parse(text) } catch (e) {} tp.loading = false } }
  }
  Timer { interval: 15000; repeat: true; triggeredOnStart: true; running: tp.visible && tp.have; onTriggered: if (!col.running) { tp.loading = true; col.running = true } }

  // a link's name the way people say it
  function linkName(dev) {
    var i = (d.interfaces || []).filter(function(x) { return x.name === dev })[0]
    return i ? i.label.replace("Tunnel (tun)", t("Туннель", "Tunnel")) + "  ·  " + dev : dev
  }
  readonly property var eg: d.egress && d.egress.v4 ? d.egress.v4 : null
  readonly property var pub: d.public && d.public.info ? d.public.info : null
  readonly property var leak: d.egress ? d.egress.dnsLeak : null

  component Card: SH.HubCard {
    width: tp.width
    height: inner.implicitHeight + SH.HubStyle.pad * 2
    fg: tp.fg; accent: tp.accent
    default property alias content: inner.data
    Column { id: inner; x: SH.HubStyle.pad; y: SH.HubStyle.pad; width: parent.width - SH.HubStyle.pad * 2; spacing: Style.space(10) }
  }

  Card {
    visible: !tp.have
    Text { width: parent.width; wrapMode: Text.Wrap; text: tp.t("Для этой вкладки нужен плагин Bananet (banan.bananet) — включать его не обязательно, достаточно, чтобы он был установлен.", "This tab needs the Bananet plugin (banan.bananet) installed — it doesn't have to be on."); color: tp.fg; font.family: tp.ff; font.pixelSize: Style.font.caption + 1 }
  }

  // the way out
  Card {
    visible: tp.have
    SH.HubCaption { text: tp.t("Куда уходит трафик", "Where the traffic goes"); icon: "\u{f046a}"; fg: tp.fg; fontFamily: tp.ff }
    Text { visible: !tp.eg; text: tp.loading ? tp.t("Смотрю…", "Looking…") : tp.t("Нет данных", "No data"); color: Qt.darker(tp.fg, 1.5); font.family: tp.ff; font.pixelSize: Style.font.caption }
    Row {
      visible: !!tp.eg
      spacing: Style.space(10)
      component Hop: Rectangle {
        property string glyph: ""
        property string head: ""
        property string sub: ""
        width: Math.max(Style.space(120), hc.implicitWidth + Style.space(20)); height: Style.space(62); radius: Style.space(12)
        color: SH.HubStyle.tint(tp.fg, 0.06)
        Column {
          id: hc
          anchors.centerIn: parent
          spacing: Style.space(2)
          Text { anchors.horizontalCenter: parent.horizontalCenter; text: parent.parent.glyph + "  " + parent.parent.head; color: tp.fg; font.family: tp.ff; font.pixelSize: Style.font.caption + 1; font.bold: true }
          Text { anchors.horizontalCenter: parent.horizontalCenter; text: parent.parent.sub; color: Qt.darker(tp.fg, 1.5); font.family: tp.ff; font.pixelSize: Style.font.caption - 1 }
        }
      }
      component Arrow: Text { anchors.verticalCenter: parent.verticalCenter; text: "\u{f0054}"; color: tp.accent; font.family: tp.ff; font.pixelSize: Style.font.body + 4 }
      Hop { glyph: "\u{f0379}"; head: tp.t("Этот компьютер", "This computer"); sub: tp.eg ? tp.eg.src : "" }
      Arrow {}
      Hop { glyph: "\u{f0582}"; head: tp.eg ? tp.linkName(tp.eg.dev) : ""; sub: tp.eg ? tp.t("шлюз ", "gateway ") + tp.eg.gateway : "" }
      Arrow {}
      Hop {
        glyph: "\u{f059f}"
        head: tp.d.public ? (tp.d.public.v4 || "") : ""
        sub: tp.pub ? [tp.pub.city, tp.pub.country, String(tp.pub.org || "").replace(/^AS\d+\s*/, "")].filter(function(x) { return x }).join(" · ") : ""
      }
    }
  }

  // names
  Card {
    visible: tp.have && !!tp.leak
    SH.HubCaption { text: tp.t("Имена сайтов (DNS)", "Site names (DNS)"); icon: "\u{f0317}"; fg: tp.fg; fontFamily: tp.ff }
    Row {
      spacing: Style.space(10)
      Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Style.space(12); height: width; radius: width / 2; color: tp.leak && tp.leak.leaking ? Color.urgent : "#30d158" }
      Text {
        width: tp.width - Style.space(60); wrapMode: Text.Wrap
        text: !tp.leak ? "" : tp.leak.leaking
          ? tp.t("Трафик идёт через ", "Traffic leaves through ") + tp.leak.egressDev + tp.t(", а запросы имён — мимо него, на ", ", but name lookups skip it and go to ") + (tp.leak.servers || []).join(", ") + tp.t(" через ", " over ") + tp.leak.dnsDev + tp.t(". Тот, кто держит эту сеть (роутер, провайдер), видит, какие сайты вы открываете. Включите в приложении туннеля опцию для DNS (обычно «DNS через туннель» / «перехват DNS»).", ". Whoever runs that network (router, ISP) sees which sites you open. Turn on the tunnel app's DNS option (often “DNS through the tunnel” / “hijack DNS”).")
          : tp.t("Имена спрашиваются тем же путём, что и трафик: ", "Names go the same way as the traffic: ") + (tp.leak.servers || []).join(", ")
        color: tp.fg; font.family: tp.ff; font.pixelSize: Style.font.caption + 1
      }
    }
  }

  // apps
  Card {
    visible: tp.have && (tp.d.processes || []).length > 0
    SH.HubCaption { text: tp.t("Приложения в сети", "Apps on the network"); icon: "\u{f003b}"; fg: tp.fg; fontFamily: tp.ff }
    Repeater {
      model: (tp.d.processes || []).slice(0, 12)
      delegate: Item {
        required property var modelData
        readonly property var e: DesktopEntries.heuristicLookup(String(modelData.name).replace(/-bin$/, ""))
        width: parent.width; height: Style.space(28)
        IconImage { anchors.verticalCenter: parent.verticalCenter; width: Style.space(18); height: width; source: parent.e && parent.e.icon ? Quickshell.iconPath(parent.e.icon, true) : "" }
        Text { x: Style.space(26); anchors.verticalCenter: parent.verticalCenter; text: (parent.e && parent.e.name ? parent.e.name : modelData.name) + "  ·  " + modelData.count + tp.t(" соед.", " conn."); color: tp.fg; font.family: tp.ff; font.pixelSize: Style.font.caption + 1 }
        Text {
          anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
          text: (modelData.byDev || []).map(function(b) { return b.dev + " " + b.count }).join("  ·  ")
          color: Qt.darker(tp.fg, 1.4); font.family: tp.ff; font.pixelSize: Style.font.caption
        }
      }
    }
  }

  // who listens
  Card {
    visible: tp.have && (tp.d.listeners || []).length > 0
    SH.HubCaption { text: tp.t("Кто ждёт входящих подключений", "What accepts incoming connections"); icon: "\u{f033e}"; fg: tp.fg; fontFamily: tp.ff }
    Text { width: parent.width; wrapMode: Text.Wrap; text: tp.t("«Все сети» — к порту могут подключиться и из домашней сети; ufw решает, пустить ли.", "“All networks” — the home network can reach the port too; ufw decides whether to let it in."); color: Qt.darker(tp.fg, 1.5); font.family: tp.ff; font.pixelSize: Style.font.caption - 1 }
    Repeater {
      // one line per program and port
      model: { var seen = {}, out = []; (tp.d.listeners || []).forEach(function(l) { var k = l.proc + l.port + l.proto; if (!seen[k] && l.scope !== "loopback") { seen[k] = 1; out.push(l) } }); return out.slice(0, 14) }
      delegate: Item {
        required property var modelData
        width: parent.width; height: Style.space(24)
        Text { text: modelData.proc || "?"; color: tp.fg; font.family: tp.ff; font.pixelSize: Style.font.caption + 1 }
        Text { x: parent.width * 0.4; text: modelData.proto.toUpperCase() + " " + modelData.port; color: tp.accent; font.family: tp.ff; font.pixelSize: Style.font.caption + 1 }
        Text { anchors.right: parent.right; text: modelData.scope === "all" ? tp.t("все сети", "all networks") : modelData.scope; color: modelData.scope === "all" ? tp.fg : Qt.darker(tp.fg, 1.5); font.family: tp.ff; font.pixelSize: Style.font.caption }
      }
    }
  }

  // Tailscale
  Card {
    visible: tp.have && !!(tp.d.tailscale && tp.d.tailscale.installed)
    SH.HubCaption { text: "Tailscale"; icon: "\u{f0318}"; fg: tp.fg; fontFamily: tp.ff }
    Text {
      width: parent.width; wrapMode: Text.Wrap
      text: !tp.d.tailscale ? "" : tp.d.tailscale.running
        ? tp.t("Работает · ", "Running · ") + (tp.d.tailscale.self ? tp.d.tailscale.self.dns : "") + " · " + (tp.d.tailscale.peers || []).length + tp.t(" устройств в сети", " devices on the tailnet")
        : tp.t("Остановлен (", "Stopped (") + tp.d.tailscale.state + tp.t("). Включается командой tailscale up.", "). Start it with tailscale up.")
      color: tp.fg; font.family: tp.ff; font.pixelSize: Style.font.caption + 1
    }
  }
  Text { visible: tp.have; text: tp.t("Обновляется каждые 15 секунд, пока открыта вкладка · данные: Bananet", "Refreshes every 15 s while open · data: Bananet"); color: Qt.darker(tp.fg, 1.8); font.family: tp.ff; font.pixelSize: Style.font.caption - 2 }
}
