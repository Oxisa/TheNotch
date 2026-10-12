import QtQuick
import Quickshell
import qs.Commons
import "../.."

// Screenshot: controls for Omarchy's own screenshot tool — what to capture
// (smart, a region, a window, the whole screen), what to do with it (copy
// and save, copy, save), a delay, and the latest shots to open in the editor.
// Centre's Screenshot tile uses the same choices.
NotchModule {
  id: sc
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Скриншот", "Screenshot")
  icon: "\u{f0100}"
  description: t("Снимки экрана: область, окно или весь экран, с задержкой", "Screenshots: a region, a window or the whole screen, with a delay")
  pageWidth: 520
  page: Component { ScreenshotPage { mod: sc } }
  function opt(key, fallback) { return notch ? notch.moduleOpt("screenshot", key, fallback) : fallback }
  function persist(values) { if (notch) notch.modulePersist("screenshot", values) }
  readonly property string mode: String(opt("mode", "region"))       // smart | region | windows | fullscreen
  readonly property string action: String(opt("action", "slurp"))    // slurp (copy + save) | copy | save
  readonly property int delay: Number(opt("delay", 0))
  readonly property string folder: Quickshell.env("OMARCHY_SCREENSHOT_DIR") || (Quickshell.env("HOME") + "/Pictures")
  function shoot() {
    if (notch) { notch.expanded = false; notch.settingsOpen = false }
    Quickshell.execDetached(["bash", "-c", "sleep \"$0\"; omarchy-capture-screenshot \"$1\" \"$2\"", String(Math.max(0.4, delay)), mode, action])
  }
}
