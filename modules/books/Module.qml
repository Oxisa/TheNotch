import QtQuick
import Quickshell
import qs.Commons
import "../.."

// Books: a desktop widget with a book's cover, title, author and how far
// you've read it in Foliate; a click opens it there. It shows the book read
// last, a random one, or each in turn from your folders (and the books
// Foliate has opened). Any number of copies (DeskCopies), each with its own
// folders and look; BooksFeed runs one widget. bin/booksctl reads the books
// and Foliate's data. Widget only: no dashboard.
NotchModule {
  id: bm
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Книги", "Books")
  icon: "\u{f00be}"
  description: t("Обложка, автор и прогресс книги из Foliate на рабочем столе", "A book's cover, author and Foliate progress on the desktop")
  inRail: false
  function opt(key, fallback) { return notch ? notch.moduleOpt("books", key, fallback) : fallback }
  function persist(values) { if (notch) notch.modulePersist("books", values) }
  readonly property string home: Quickshell.env("HOME")

  widgetTitle: t("Книги", "Books")
  widgetIcon: "\u{f00be}"
  widgetPage: Component { BooksSettings { mod: bm } }
  deskEnabled: opt("widget", false) === true
  function setDeskEnabled(on) { persist({ widget: on }) }
  deskDefault: ({ x: 0.06, y: 0.40 })
  deskWidget: Component { BooksWidget { mod: bm } }
  DeskCopies {
    id: copiesObj
    mod: bm
    icon: "\u{f00be}"
    defaultPos: bm.deskDefault
    component: Component { BooksWidget { mod: bm } }
  }
  readonly property var copies: copiesObj
  deskList: copiesObj.list

  Instantiator {
    id: feeds
    model: copiesObj.wids
    delegate: BooksFeed { required property string modelData; mod: bm; wid: modelData }
  }
  function feed(wid) {
    var w = wid || moduleId
    for (var i = 0; i < feeds.count; i++) { var f = feeds.objectAt(i); if (f && f.wid === w) return f }
    return null
  }

  readonly property string bin: decodeURIComponent(Qt.resolvedUrl("bin/booksctl").toString().replace(/^file:\/\//, ""))
  function open(b) { if (b) Quickshell.execDetached([bin, "open", b.path]) }
  function url(p) { return p ? "file://" + p.split("/").map(encodeURIComponent).join("/") : "" }

  // fonts, as for the quotes and the clock: the widget font, the quotes'
  // blackletter, a serif, or any installed family
  FontLoader { id: gothic; source: Qt.resolvedUrl("../../vendor/dailyquote/fonts/UnifrakturMaguntia-Book.ttf") }
  function fontOf(choice, fallback) {
    return choice === "default" || !choice ? fallback : choice === "gothic" ? gothic.name : choice === "serif" ? "Noto Serif" : choice
  }
}
