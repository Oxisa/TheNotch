import QtQuick
import Quickshell
import Quickshell.Io
import "../.."
import "../../../osia.dailyquote/settings.js" as DQ

// Daily Quote as a TheNotch dashboard. The quote and its desktop overlay
// belong to the osia.dailyquote plugin; this reads the same files (current
// quote, settings) and drives it over its IPC, so both always agree.
//   page   the quote in blackletter + translation, New / Copy, and the
//          overlay's settings (show, how often, move it)
//   event  a new quote flashes out of the notch
NotchModule {
  id: qmod
  title: t("title")
  icon: "\u{f0757}"
  description: t("desc")
  sectionOrder: 12

  // ------------------------------------------- widget: the desktop quote
  // Drawn by the osia.dailyquote plugin while it is on (it reads the same
  // settings); with the plugin off, this module draws it itself.
  widgetTitle: t("widget")
  widgetIcon: "\u{f0757}"
  widgetPage: Component { QuoteWidget { mod: qmod } }
  readonly property bool hostOverlay: active && notch !== null && notch.omarchyPlugins.length > 0
                                      && !notch.pluginEnabled("osia.dailyquote")
  Loader {
    active: qmod.hostOverlay
    source: Qt.resolvedUrl("../../../osia.dailyquote/Service.qml")
  }
  pageWidth: 460
  page: Component { Page { mod: qmod } }
  settingsPage: Component { QuoteSettings { mod: qmod } }

  readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/omarchy/dailyquote"
  readonly property string fontUrl: Qt.resolvedUrl("../../../osia.dailyquote/fonts/UnifrakturMaguntia-Book.ttf")

  readonly property var strings: ({
    en: { title: "Quotes", desc: "A quote of the day on the desktop and in the notch", widget: "Quote on the desktop",
          lang: "Translation", fresh: "New quote", copy: "Copy", copied: "Copied", show: "Show on the desktop",
          place: "Position", size: "Size", background: "Background", reset: "Reset",
          change: "Change it", move: "Move on the desktop", none: "No quote yet" },
    ru: { title: "Цитаты", desc: "Цитата дня на рабочем столе и в чёлке", widget: "Цитата на рабочем столе",
          lang: "Язык перевода", fresh: "Новая цитата", copy: "Копировать", copied: "Скопировано", show: "Показывать на рабочем столе",
          place: "Положение", size: "Размер", background: "Фон", reset: "Сбросить",
          change: "Смена цитаты", move: "Переместить на рабочем столе", none: "Цитаты пока нет" }
  })
  function t(k) { var lang = notch ? notch.lang : "en"; return (strings[lang] || strings.en)[k] || strings.en[k] || k }
  function every(minutes) { return DQ.t(notch ? notch.lang : "en", "every")[minutes] }

  // ------------------------------------------------- the plugin's files
  property var quote: null
  // bin/dailyquote replaces the file atomically (rename), which an inotify
  // watch on the old file misses, so also re-read it every few seconds.
  FileView {
    id: currentFile
    path: qmod.stateDir + "/current.json"
    watchChanges: true
    printErrors: false
    onLoaded: { try { var s = JSON.parse(text()); if (s && s.current) qmod.quote = s.current } catch (e) {} }
    onFileChanged: reload()
  }
  Timer { interval: 4000; repeat: true; running: true; onTriggered: currentFile.reload() }
  property var cfg: DQ.parse("")
  FileView {
    id: cfgFile
    path: qmod.stateDir + "/settings.json"
    watchChanges: true
    printErrors: false
    onLoaded: qmod.cfg = DQ.parse(text())
    onFileChanged: reload()
  }
  function set(key, value) { var v = {}; v[key] = value; setMany(v) }
  function setMany(values) {
    var c = {}
    for (var k in cfg) c[k] = cfg[k]
    for (var key in values) c[key] = values[key]
    cfg = DQ.parse(JSON.stringify(c))
    cfgFile.setText(JSON.stringify(cfg))
  }
  readonly property string place: DQ.placeOf(cfg)
  function resetLook() { setMany(DQ.resetLook()) }
  // original on top (any language), translation into the plugin's language under it
  readonly property string upper: DQ.topOf(quote)
  readonly property string lower: DQ.bottomOf(quote, cfg.lang)
  function fontFor(gothicName) { return DQ.fontFor(DQ.langOf(quote), gothicName) }
  function setPlace(p) { setMany({ posX: DQ.PLACES[p][0], posY: DQ.PLACES[p][1] }) }

  function ipc(cmd) { Quickshell.execDetached(["qs", "-p", Quickshell.shellDir, "ipc", "call", "osia.dailyquote", cmd]) }
  function next() { ipc("next") }
  function move() { if (notch) notch.expanded = false; ipc("edit") }
  function copy() {
    if (!quote) return
    var txt = upper + (lower ? "\n" + lower : "") + (quote.author ? "\n— " + quote.author : "")
    Quickshell.execDetached(["wl-copy", txt])
  }

  // ------------------------------------------------------------ event
  readonly property string sig: DQ.topOf(quote)
  property string lastSig: ""
  onSigChanged: {
    if (!sig || sig === lastSig) return
    var first = lastSig === ""
    lastSig = sig
    if (first || !notch || !qmod.active) return
    notch.flash({ key: "quote", big: true, icon: "\u{f0757}", title: quote.author || t("title"),
                  message: lower || upper, ms: 6000, action: function() { notch.openModule("quote") } })
  }
}
