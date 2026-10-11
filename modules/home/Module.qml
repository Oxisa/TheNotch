import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."

// Home: the first tab of the open notch, laid out after the caelestia
// shell's dashboard (the layout idea only — no code taken): weather and a
// profile card on top, the player down the right side, the date, the month
// and resource bars below. Nothing else — the rest is in Centre.
NotchModule {
  id: hm
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Главная", "Home")
  icon: "\u{f056e}"
  description: t("Погода, профиль, дата и календарь, ресурсы и плеер — как в caelestia",
                 "Weather, profile, date and calendar, resources and the player — after caelestia")
  topTab: true
  pageWidth: 820
  page: Component { HomePage { mod: hm } }
  function moduleById(id) { return notch ? notch.moduleById(id) : null }

  property string osName: "Linux"
  FileView {
    path: "/etc/os-release"
    printErrors: false
    onLoaded: { var m = text().match(/^PRETTY_NAME="?([^"\n]+)"?/m); if (m) hm.osName = m[1] }
  }
  property real uptime: 0
  FileView { id: up; path: "/proc/uptime"; printErrors: false; onLoaded: hm.uptime = parseFloat(text()) }
  Timer { interval: 60000; repeat: true; running: hm.notch !== null && hm.notch.expanded; triggeredOnStart: true; onTriggered: up.reload() }
  function upText() {
    var s = uptime, d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60)
    return t("работает ", "up ") + (d ? d + t(" д ", "d ") : "") + (d || h ? h + t(" ч ", "h ") : "") + m + t(" мин", "m")
  }
}
