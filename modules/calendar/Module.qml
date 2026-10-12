import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."

// Calendar: events from ICS subscriptions (Google, Outlook, iCloud — the
// secret iCal link, no sign-in) and your own, shown as dots in Home's month,
// a month-and-agenda tool in Centre, and reminders in the notch before an
// event with "Join" for a call link. bin/calctl does the reading. After
// Datebook (jonspinks) — the idea, not its code.
NotchModule {
  id: cal
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Календарь", "Calendar")
  icon: "\u{f00f0}"
  description: t("События из Google, Outlook, iCloud по ссылке и свои; напоминания в чёлке", "Events from Google, Outlook, iCloud by link and your own; reminders in the notch")
  pageWidth: 640
  page: Component { CalendarPage { mod: cal } }
  settingsPage: Component { CalendarSettings { mod: cal } }
  sectionOrder: 16
  function opt(key, fallback) { return notch ? notch.moduleOpt("calendar", key, fallback) : fallback }
  function persist(values) { if (notch) notch.modulePersist("calendar", values) }

  readonly property string bin: decodeURIComponent(Qt.resolvedUrl("bin/calctl").toString().replace(/^file:\/\//, ""))
  property var events: []
  property var errors: []
  property var queue: []
  Process {
    id: proc
    property var args: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var d = JSON.parse(text)
          if (proc.args[0] === "events") { cal.events = d.events || []; cal.errors = d.errors || [] }
          else cal.cmd(["events"])
        } catch (e) {}
        cal.next()
      }
    }
  }
  function next() {
    if (proc.running || !queue.length) return
    proc.args = queue[0]; queue = queue.slice(1)
    proc.command = [bin].concat(proc.args); proc.running = true
  }
  function cmd(args) { queue = queue.concat([args]); next() }
  function refresh(force) { cmd(force ? ["events", "--refresh"] : ["events"]) }
  Timer { interval: 15 * 60000; repeat: true; triggeredOnStart: true; running: cal.active; onTriggered: cal.refresh(false) }

  // subscriptions (kept in ~/.config/thenotch/calendars.json for calctl)
  FileView {
    id: subsFile
    path: Quickshell.env("HOME") + "/.config/thenotch/calendars.json"
    printErrors: false
    onLoaded: { try { cal.subs = JSON.parse(text()) } catch (e) { cal.subs = [] } }
    onLoadFailed: cal.subs = []
  }
  property var subs: []
  function saveSubs(list) { subs = list; subsFile.setText(JSON.stringify(list, null, 1)); refresh(true) }
  readonly property var palette: ["#61afef", "#e06c75", "#98c379", "#e5b450", "#c678dd", "#56b6c2"]

  // the events of one day (local), all-day ones first
  function dayKey(d) { return d.getFullYear() + "-" + (d.getMonth() + 1) + "-" + d.getDate() }
  function eventsOn(d) {
    var s = new Date(d.getFullYear(), d.getMonth(), d.getDate()), e = new Date(s.getTime() + 86400000)
    return events.filter(function(ev) { var a = new Date(ev.start), b = new Date(ev.end); return a < e && b > s && !(ev.allDay && b <= s) })
                 .sort(function(x, y) { return (y.allDay - x.allDay) || (new Date(x.start) - new Date(y.start)) })
  }
  function colorOf(ev) { return ev.own ? Color.accent : (ev.color || Color.accent) }
  function timeOf(ev) { return ev.allDay ? t("весь день", "all day") : Qt.formatTime(new Date(ev.start), "HH:mm") + "–" + Qt.formatTime(new Date(ev.end), "HH:mm") }
  function add(ev) { cmd(["add", JSON.stringify(ev)]) }
  function remove(id) { cmd(["remove", id]) }
  property date picked: new Date()

  // reminders: N minutes before a timed event, once
  readonly property int remind: Number(opt("remind", 10))
  property var reminded: ({})
  Timer {
    interval: 30000; repeat: true; running: cal.active && cal.remind > 0
    onTriggered: {
      var now = Date.now()
      for (var i = 0; i < cal.events.length; i++) {
        var ev = cal.events[i], st = new Date(ev.start).getTime()
        if (ev.allDay || cal.reminded[ev.id] || st - now > cal.remind * 60000 || st < now - 60000) continue
        var r = Object.assign({}, cal.reminded); r[ev.id] = true; cal.reminded = r
        var link = ev.link
        if (cal.notch) cal.notch.flash({ key: "cal-" + ev.id, big: true, icon: "\u{f00f0}", title: ev.title,
          message: Qt.formatTime(new Date(ev.start), "HH:mm") + (link ? cal.t(" · нажмите, чтобы войти", " · click to join") : (ev.where ? " · " + ev.where : "")),
          ms: 15000, action: function() { if (link) Quickshell.execDetached(["xdg-open", link]); else cal.notch.openModule("calendar") } })
      }
    }
  }
}
