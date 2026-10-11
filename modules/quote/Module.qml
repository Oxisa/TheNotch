import QtQuick
import Quickshell
import Quickshell.Io
import "../.."
import "../../../osia.dailyquote" as DQP
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
  // TheNotch's widget layer draws the quote card while the Daily Quote plugin
  // is off (with it on, the plugin draws its own and this stays out of the
  // way); the notch then keeps the quote fresh itself with the plugin's script.
  readonly property bool pluginOn: notch !== null && notch.pluginEnabled("osia.dailyquote")
  readonly property bool hosting: active && notch !== null && notch.omarchyPlugins.length > 0 && !pluginOn
  readonly property string helper: decodeURIComponent(Qt.resolvedUrl("../../../osia.dailyquote/bin/dailyquote").toString().replace(/^file:\/\//, ""))
  Process { id: fetch }
  function runHelper(args) { if (!fetch.running) { fetch.command = [helper].concat(args); fetch.running = true } }
  Timer {
    interval: 60000; repeat: true; triggeredOnStart: true
    running: qmod.hosting
    onTriggered: qmod.runHelper(["get", String(qmod.cfg.intervalMinutes), qmod.cfg.lang])
  }
  deskEnabled: hosting && cfg.visible
  function setDeskEnabled(on) { set("visible", on) }
  deskDefault: ({ x: 0.30, y: 0.78 })
  deskWidget: Component {
    DQP.QuoteCard {
      readonly property bool deskShown: qmod.quote !== null || editing
      property bool deskVertical: false          // turned 90°: vertical writing, upright
      property var deskStyle: ({})
      quote: qmod.quote
      // the shared Style's background opacity wins over the quote's own setting
      cfg: {
        var c = {}, src = deskVertical ? qmod.verticalCfg : qmod.cfg
        for (var k in src) c[k] = src[k]
        if (deskStyle && deskStyle.bgOpacity !== undefined) c.backgroundOpacity = deskStyle.bgOpacity
        return c
      }
      s: qmod.cfg.scale
    }
  }
  pageWidth: 460
  page: Component { Page { mod: qmod } }
  settingsPage: Component { QuoteSettings { mod: qmod } }

  readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/omarchy/dailyquote"
  readonly property string fontUrl: Qt.resolvedUrl("../../../osia.dailyquote/fonts/UnifrakturMaguntia-Book.ttf")

  readonly property var strings: ({
    en: { title: "Quotes", desc: "A quote of the day on the desktop and in the notch", widget: "Quote on the desktop",
          lang: "Translation", orientation: "Orientation", horizontal: "Horizontal", vertical: "Vertical", origLangs: "Original languages", origLangsHint: "Off: such quotes show their translation instead", fresh: "New quote", copy: "Copy", copied: "Copied", show: "Show on the desktop",
          place: "Position", size: "Size", background: "Background", reset: "Reset", arrange: "Arrange widgets",
          change: "Change it", sources: "Sources", sourcesHint: "Where new quotes come from", sayings: "Sayings", bible: "Bible",
          commentary: "Commentary", commentaryHint: "Matthew Henry, in English", noCommentary: "No commentary for this verse", move: "Move on the desktop", none: "No quote yet" },
    ru: { title: "Цитаты", desc: "Цитата дня на рабочем столе и в чёлке", widget: "Цитата на рабочем столе",
          lang: "Язык перевода", orientation: "Ориентация", horizontal: "Горизонтально", vertical: "Вертикально", origLangs: "Языки оригинала", origLangsHint: "Выключенный язык — вместо оригинала покажется перевод", fresh: "Новая цитата", copy: "Копировать", copied: "Скопировано", show: "Показывать на рабочем столе",
          place: "Положение", size: "Размер", background: "Фон", reset: "Сбросить", arrange: "Расставить виджеты",
          change: "Смена цитаты", sources: "Источники", sourcesHint: "Откуда берутся новые цитаты", sayings: "Изречения", bible: "Библия",
          commentary: "Толкование", commentaryHint: "Мэтью Генри, на английском", noCommentary: "Для этого стиха толкования нет", move: "Переместить на рабочем столе", none: "Цитаты пока нет" }
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
  readonly property var verticalCfg: { var c = {}; for (var k in cfg) c[k] = cfg[k]; c.orientation = "vertical"; return c }
  function resetLook() { setMany(DQ.resetLook()) }
  // original on top (any language), translation into the plugin's language under it
  // honours the original languages switched off in the settings
  readonly property var shown: DQ.view(quote, cfg)
  readonly property string upper: shown.top
  readonly property string lower: shown.bottom
  function fontFor(gothicName) { return DQ.fontFor(shown.topLang, gothicName) }
  function toggleLang(code) {
    var h = cfg.hideLangs.slice()
    if (h.indexOf(code) >= 0) h = h.filter(function(x) { return x !== code }); else h.push(code)
    set("hideLangs", h)
  }
  // at least one source stays on; a change brings a quote from the new mix
  function toggleSource(code) {
    var src = cfg.sources.slice()
    if (src.indexOf(code) >= 0) { if (src.length === 1) return; src = src.filter(function(x) { return x !== code }) }
    else src.push(code)
    set("sources", src)
    next()
  }
  // a verse's commentary (Matthew Henry via bible.helloao.org), on request
  readonly property bool isVerse: quote !== null && quote.source === "Bible" && !!quote.ref
  property string commentary: ""
  property string commentaryFor: ""
  property bool commentaryBusy: false
  Process {
    id: comm
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        qmod.commentaryBusy = false
        var out = ""
        try {
          var d = JSON.parse(text), v = qmod.quote.ref.verse, best = null
          var c = d.chapter && d.chapter.content ? d.chapter.content : []
          for (var i = 0; i < c.length; i++)
            if (c[i].type === "verse" && Number(c[i].number) <= v) best = c[i]
          if (best) out = best.content.map(function(x) { return typeof x === "string" ? x : (x.text || "") }).join(" ").trim()
        } catch (e) {}
        qmod.commentary = out || qmod.t("noCommentary")
      }
    }
  }
  function loadCommentary() {
    if (!isVerse || comm.running) return
    var r = quote.ref, k = r.book + r.chapter + ":" + r.verse
    if (k === commentaryFor && commentary) return
    commentaryFor = k; commentary = ""; commentaryBusy = true
    comm.command = ["curl", "-fsS", "--max-time", "30", "https://bible.helloao.org/api/c/matthew-henry/" + r.book + "/" + r.chapter + ".json"]
    comm.running = true
  }
  onQuoteChanged: if (commentaryFor && isVerse && commentaryFor !== quote.ref.book + quote.ref.chapter + ":" + quote.ref.verse) { commentary = ""; commentaryFor = "" }
  function setPlace(p) { setMany({ posX: DQ.PLACES[p][0], posY: DQ.PLACES[p][1] }) }

  function ipc(cmd) { Quickshell.execDetached(["qs", "-p", Quickshell.shellDir, "ipc", "call", "osia.dailyquote", cmd]) }
  function next() { if (pluginOn) ipc("next"); else runHelper(["next", cfg.lang]) }
  function move() { if (notch) notch.editLayout(true) }
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
