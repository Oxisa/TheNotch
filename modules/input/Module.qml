import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."

// Input: mouse and touchpad (speed, acceleration, scrolling), key repeat,
// the keyboard layouts (read only — Omalang manages them) and every key
// binding, searchable. bin/inputctl applies a change at once (hyprctl eval)
// and keeps it in its own block of ~/.config/hypr/input.lua. The bindings
// list after Visual Keybindings / Shortkeyz — the idea, not their code.
NotchModule {
  id: im
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Ввод", "Input")
  icon: "\u{f030c}"
  description: t("Мышь, тачпад, клавиатура и горячие клавиши", "Mouse, touchpad, keyboard and key bindings")
  inRail: false
  settingsSection: "input"
  sectionOrder: 1
  settingsPage: Component { InputSettings { mod: im } }

  readonly property string bin: decodeURIComponent(Qt.resolvedUrl("bin/inputctl").toString().replace(/^file:\/\//, ""))
  property var st: ({ values: {}, layouts: [], binds: [], mice: [] })
  property var queue: []
  Process {
    id: proc
    property var args: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: { try { var d = JSON.parse(text); if (proc.args[0] === "state") im.st = d } catch (e) {} im.next() }
    }
  }
  function next() {
    if (proc.running || !queue.length) return
    proc.args = queue[0]; queue = queue.slice(1)
    proc.command = [bin].concat(proc.args); proc.running = true
  }
  function cmd(args) { queue = queue.concat([args]); next() }
  function set(key, value) {
    var v = {}; for (var k in st.values) v[k] = st.values[k]; v[key] = value
    st = Object.assign({}, st, { values: v })                 // show it at once
    cmd(["set", key, String(value)])
  }
  // keyboard layouts: the XKB list (loaded when needed) and edits
  property var allLayouts: []
  Process {
    id: lay
    command: [im.bin, "layouts"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: { try { im.allLayouts = JSON.parse(text).layouts } catch (e) {} } }
  }
  function loadAll() { if (!allLayouts.length && !lay.running) lay.running = true }
  function layoutName(code) {
    for (var i = 0; i < allLayouts.length; i++) if (allLayouts[i].code === code) return allLayouts[i].name
    return code.toUpperCase()
  }
  Component.onCompleted: loadAll()
  function saveLayouts(list) {
    st = Object.assign({}, st, { layouts: list })
    cmd(["setlayouts", list.join(",")]); cmd(["state"])
  }
  function addLayout(code) { var l = st.layouts.slice(); if (l.indexOf(code) < 0) { l.push(code); saveLayouts(l) } }
  function removeLayout(i) { var l = st.layouts.slice(); if (l.length > 1) { l.splice(i, 1); saveLayouts(l) } }
  function moveLayout(i, d) { var l = st.layouts.slice(), j = i + d; if (j < 0 || j >= l.length) return; var x = l[i]; l[i] = l[j]; l[j] = x; saveLayouts(l) }

  readonly property bool watching: active && notch !== null && notch.settingsOpen && notch.settingsSection === "input"
  onWatchingChanged: if (watching) cmd(["state"])
}
