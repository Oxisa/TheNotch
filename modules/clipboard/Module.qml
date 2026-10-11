import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."

// Clipboard: the recent copies (text and pictures) to copy again with one
// click. The history itself is Omarchy's (its clipboard plugin records it to
// ~/.local/state/omarchy/clipboard-history.json, skipping passwords); this
// only shows it and copies with Omarchy's own command.
NotchModule {
  id: cb
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Буфер обмена", "Clipboard")
  icon: "\u{f0a38}"
  description: t("Последние скопированные тексты и картинки — скопировать снова в один клик",
                 "Recent copies, text and pictures — copy again in one click")
  pageWidth: 520
  page: Component { ClipboardPage { mod: cb } }

  property var history: []
  FileView {
    id: file
    path: Quickshell.env("HOME") + "/.local/state/omarchy/clipboard-history.json"
    watchChanges: true
    printErrors: false
    onLoaded: { try { var h = JSON.parse(text()); cb.history = Array.isArray(h) ? h : [] } catch (e) {} }
    onFileChanged: reload()
  }
  // the file is replaced on save, which a watch can miss
  Timer { interval: 3000; repeat: true; running: cb.active && cb.notch !== null && cb.notch.expanded; onTriggered: file.reload() }

  property int copiedIndex: -1
  function copy(i) {
    var e = history[i]
    if (!e) return
    if (e.type === "image") Quickshell.execDetached(["bash", "-c", "wl-copy --type \"$1\" < \"$2\"", "_", e.mime || "image/png", e.path])
    else Quickshell.execDetached(["omarchy-clipboard-paste-text", "--copy-only", "--history-index", String(i)])
    copiedIndex = i; resetCopied.restart()
  }
  Timer { id: resetCopied; interval: 1500; onTriggered: cb.copiedIndex = -1 }
  function preview(e) { return e ? (e.type === "image" ? t("Картинка", "Picture") + (e.capturedAt ? " · " + e.capturedAt : "") : String(e.text || "").replace(/\s+/g, " ").trim()) : "" }

}
