import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."
import "../../vendor/soundhub" as SH
import "../../fonts"

// Agents: your coding agents and their limits in the notch.
//   ask     Enter = a quick read-only answer right in the notch (the agent
//           runs headless with no tools); Shift+Enter or ↗ = the full agent in
//           a terminal with that prompt (the way `omarchy agent` launches it)
//   limits  read-only from Omarchy's own collector (omarchy.agents writes
//           ~/.local/state/omarchy/agents/usage/*.json) — no credentials are
//           read here. Claude and Codex report limits; Gemini and opencode
//           have none to report, so they show only what is honest.
//   live    a limit pops out in the collapsed notch for a few seconds when
//           it crosses the threshold, then again every `step` % above it,
//           and when it resets; "always" keeps it there instead
//   rings   one nested ring per agent with limits (Claude, Codex): outer =
//           session, inner = week / window; Gemini and opencode have no
//           limit source, so they appear only as agents to ask
//   widget  "Agent limits" on the desktop (Settings → Widgets)
// Idea and data contract from Bappoz/omarchy-ai-usage (MIT).
NotchModule {
  id: am
  readonly property bool ru: notch !== null && notch.lang === "ru"
  title: ru ? "Агенты" : "Agents"
  icon: "\u{f06a9}"
  description: ru ? "Спросить агента из чёлки и следить за лимитами Claude, Codex и других"
                  : "Ask an agent from the notch and watch Claude, Codex and other limits"
  sectionOrder: 13
  pageWidth: 440
  page: Component { Page { mod: am } }
  settingsPage: Component { AgentsSettings { mod: am } }

  function opt(key, fallback) { return notch ? notch.moduleOpt("agents", key, fallback) : fallback }
  function persist(values) { if (notch) notch.modulePersist("agents", values) }
  function t(ruText, enText) { return ru ? ruText : enText }

  readonly property real threshold: Number(opt("threshold", 0.8))
  readonly property real step: Number(opt("step", 0.05))
  readonly property bool always: opt("always", false) === true

  // ------------------------------------------------------------ agents
  readonly property var known: [
    { id: "claude", name: "Claude", glyph: "\u{ec82}" },
    { id: "codex", name: "Codex", glyph: "\u{ec81}" },
    { id: "gemini", name: "Gemini", glyph: "\u{f0674}" },
    { id: "opencode", name: "opencode", glyph: "\u{f018d}" }
  ]
  property var installed: []
  property string defaultAgent: ""
  Process {
    id: detect
    command: ["bash", "-c", "for a in claude codex gemini opencode; do command -v $a >/dev/null && echo $a; done; echo default=$(omarchy-default-agent 2>/dev/null)"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var lines = String(text).trim().split("\n"), list = []
        for (var i = 0; i < lines.length; i++) {
          if (lines[i].indexOf("default=") === 0) am.defaultAgent = lines[i].slice(8).trim()
          else if (lines[i]) list.push(lines[i])
        }
        am.installed = list
      }
    }
  }
  Component.onCompleted: detect.running = true

  // the selected agent for asking: chosen chip, else Omarchy's default, else the first installed
  property string chosen: String(opt("agent", ""))
  readonly property string agent: installed.indexOf(chosen) >= 0 ? chosen
    : installed.indexOf(defaultAgent) >= 0 ? defaultAgent : (installed.length ? installed[0] : "")
  function choose(id) { chosen = id; persist({ agent: id }) }

  // ------------------------------------------------------------ limits
  readonly property string usageDir: Quickshell.env("HOME") + "/.local/state/omarchy/agents/usage"
  property var records: ({})
  Process {
    id: readUsage
    command: ["bash", "-c", "for f in \"$1\"/*.json; do [ -e \"$f\" ] || continue; n=${f##*/}; printf '%s\\t' \"${n%.json}\"; tr -d '\\n' < \"$f\"; echo; done", "--", am.usageDir]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        // a file caught mid-rewrite doesn't parse: keep its last good record
        var r = {}, lines = String(text).split("\n")
        for (var k in am.records) r[k] = am.records[k]
        for (var i = 0; i < lines.length; i++) {
          var tab = lines[i].indexOf("\t")
          if (tab < 0) continue
          try { r[lines[i].slice(0, tab)] = JSON.parse(lines[i].slice(tab + 1)) } catch (e) {}
        }
        am.records = r
      }
    }
  }
  function reread() { if (!readUsage.running) readUsage.running = true }
  Timer { interval: 60000; repeat: true; running: true; triggeredOnStart: true; onTriggered: am.reread() }
  // ask Omarchy's collector for fresh numbers when the dashboard opens (≥ 60 s apart)
  property real lastUpdate: 0
  function refresh() {
    if (Date.now() - lastUpdate < 60000) { reread(); return }
    lastUpdate = Date.now()
    Quickshell.execDetached(["omarchy", "agent", "usage-update", "--limits-only"])
    rereadSoon.restart()
  }
  Timer { id: rereadSoon; interval: 8000; onTriggered: am.reread() }
  // fresh numbers every 5 minutes, so the notch can tell when a limit climbs
  Timer { interval: 300000; repeat: true; running: am.active && am.agents.length > 0; onTriggered: am.refresh() }

  // a limit's window length, from its label ("Session (5-hour)", "Weekly (7-day)")
  function windowMs(label) {
    var s = String(label || "").toLowerCase(), m
    if ((m = s.match(/(\d+)\s*-?\s*h(our)?\b/))) return Number(m[1]) * 3600e3
    if ((m = s.match(/(\d+)\s*-?\s*day/))) return Number(m[1]) * 86400e3
    if (s.indexOf("session") >= 0) return 5 * 3600e3
    if (s.indexOf("week") >= 0) return 7 * 86400e3
    return 0
  }
  property real now: Date.now()
  Timer { interval: 30000; repeat: true; running: true; onTriggered: am.now = Date.now() }
  function untilText(iso) {
    var ms = new Date(iso).getTime() - now
    if (!(ms > 0)) return ""
    var min = Math.round(ms / 60000), d = Math.floor(min / 1440), h = Math.floor((min % 1440) / 60), mm = min % 60
    if (d > 0) return d + (ru ? " дн " : " d ") + h + (ru ? " ч" : " h")
    if (h > 0) return h + (ru ? " ч " : " h ") + mm + (ru ? " мин" : " min")
    return mm + (ru ? " мин" : " min")
  }
  function shortLabel(label) {
    var s = String(label || "")
    if (/session/i.test(s)) return ru ? "Сессия · 5 ч" : "Session · 5 h"
    if (/week/i.test(s)) return ru ? "Неделя" : "Week"
    var w = windowMs(s)                              // e.g. "720h window" → "30 days"
    if (w >= 86400e3) { var d = Math.round(w / 86400e3); return ru ? "Окно · " + d + " дн" : "Window · " + d + " d" }
    if (w > 0) { var h = Math.round(w / 3600e3); return ru ? "Окно · " + h + " ч" : "Window · " + h + " h" }
    return s
  }
  function fmtTokens(n) {
    n = Number(n || 0)
    if (n >= 1e6) return (n / 1e6).toFixed(1) + "M"
    if (n >= 1e3) return Math.round(n / 1e3) + "k"
    return String(n)
  }

  readonly property var limitIds: ["claude", "codex"]
  // one ring per installed agent with an official limit collector
  readonly property var agents: {
    var out = []
    for (var i = 0; i < known.length; i++) {
      var a = known[i]
      // rings only for the agents Omarchy collects limits for; the others can still be asked
      if (installed.indexOf(a.id) < 0 || limitIds.indexOf(a.id) < 0) continue
      var r = records[a.id] || null
      var limits = []
      if (r && Array.isArray(r.limits)) for (var j = 0; j < r.limits.length; j++) {
        var l = r.limits[j], w = windowMs(l.label), left = new Date(l.resetsAt).getTime() - now
        limits.push({ label: shortLabel(l.label), percent: Number(l.percent),
                      pace: w > 0 && left > 0 ? Math.max(0, Math.min(1, 1 - left / w)) : -1,
                      reset: untilText(l.resetsAt), resetsAt: l.resetsAt })
      }
      out.push({ id: a.id, name: a.name, glyph: a.glyph, hasData: !!r, ready: r ? r.ready !== false : false,
                 limits: limits, tokens: r ? Number(r.todayTotalTokens || 0) : 0, prompts: r ? Number(r.todayPrompts || 0) : 0,
                 updated: r ? (r.updatedAt || "") : "", help: r && r.ready === false ? String(r.authHelpText || r.usageStatusText || "") : "",
                 tier: r ? String(r.tierLabel || "") : "" })
    }
    return out
  }

  // the fullest limit across agents, for the collapsed notch
  readonly property var fullest: {
    var best = null
    for (var i = 0; i < agents.length; i++) for (var j = 0; j < agents[i].limits.length; j++) {
      var l = agents[i].limits[j]
      if (!best || l.percent > best.percent) best = { agent: agents[i], limit: l, percent: l.percent }
    }
    return best
  }

  // ---------------------------------------------------- live + events
  live: always && fullest !== null && fullest.percent >= threshold
  livePriority: 5
  liveLeft: Component {
    Text { text: "\u{f06a9}"; color: Color.accent; font.family: Fonts.ui; font.pixelSize: Style.font.body + 1 }
  }
  liveRight: Component {
    Text {
      text: am.fullest ? Math.round(am.fullest.percent * 100) + "%" : ""
      color: am.fullest && am.fullest.percent >= 0.95 ? Color.urgent : Color.foreground
      font.family: Fonts.ui; font.pixelSize: Style.font.caption; font.bold: true
    }
  }
  property var lastLevels: ({})                 // agent/limit -> 0 below the threshold, then +1 every step
  property bool primed: false
  onAgentsChanged: {
    var next = {}
    for (var i = 0; i < agents.length; i++) for (var j = 0; j < agents[i].limits.length; j++) {
      var a = agents[i], l = a.limits[j], k = a.id + "/" + l.label
      var lvl = l.percent < threshold ? 0 : 1 + Math.floor((l.percent - threshold) / Math.max(0.01, step) + 1e-6)
      next[k] = lvl
      var was = lastLevels[k]
      if (!primed || !active || !notch || was === undefined) continue
      if (lvl > was)
        notch.flash({ key: "agents-" + k, icon: "\u{f06a9}", title: a.name + ": " + Math.round(l.percent * 100) + "% — " + l.label,
                      message: l.reset ? t("сброс через ", "resets in ") + l.reset : "", progress: l.percent, ms: 5000 })
      else if (was > 0 && l.percent < 0.1)
        notch.flash({ key: "agents-" + k, icon: "\u{f06a9}", title: t("Лимит сброшен", "Limit reset") + " — " + a.name,
                      message: l.label, ms: 3500 })
    }
    lastLevels = next
    if (Object.keys(next).length) primed = true
  }

  readonly property bool opened: notch !== null && notch.expanded && notch.current === am
  onOpenedChanged: if (opened) { refresh(); if (!detect.running) detect.running = true }

  // ------------------------------------------------------------ asking
  property string question: ""
  property string answer: ""
  property string askedAgent: ""
  property bool asking: false
  property string askError: ""
  readonly property string tmpOut: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/thenotch-agent-answer.txt"

  // headless and read-only: no tools, no edits — just an answer
  function askCommand(id, q) {
    switch (id) {
      case "claude": return ["claude", "-p", "--tools", "", "--output-format", "text", "--", q]
      case "codex": return ["codex", "exec", "--sandbox", "read-only", "--skip-git-repo-check", "--ephemeral", "-o", tmpOut, "--", q]
      case "gemini": return ["gemini", "--approval-mode", "plan", "-o", "text", "-p", q]
      case "opencode": return ["opencode", "run", q]
    }
    return []
  }
  function ask(q) {
    q = String(q || "").trim()
    if (!q || !agent || asking) return
    question = q; answer = ""; askError = ""; askedAgent = agent; asking = true
    // codex writes its log to stdout and the answer to a file (-o): read the file
    askProc.command = ["bash", "-c",
      "cd \"$HOME\"; out=$1; mode=$2; shift 2; err=$out.err; rm -f \"$out\" \"$err\"; " +
      "if [ \"$mode\" = file ]; then timeout 180 \"$@\" </dev/null >\"$err\" 2>&1; rc=$?; cat \"$out\" 2>/dev/null; " +
      "else timeout 180 \"$@\" </dev/null 2>\"$err\"; rc=$?; fi; " +   // no stdin: codex would wait on it
      // on failure, hand back the agent's own error line (e.g. a model it can't use)
      "if [ $rc -ne 0 ]; then printf '\\001ERR'; (grep -iE 'error|fail|denied|not supported|auth' \"$err\" || cat \"$err\") | tail -2 | cut -c1-400; fi; exit $rc",
      "--", tmpOut, agent === "codex" ? "file" : "stdout"].concat(askCommand(agent, q))
    askProc.running = true
  }
  function cancelAsk() { if (askProc.running) askProc.running = false; asking = false }
  Process {
    id: askProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var txt = String(text)
        var mark = txt.indexOf("\u0001ERR")
        if (mark >= 0) {
          var why = txt.slice(mark + 4).trim()
          var msg = why.match(/"message"\s*:\s*"([^"]+)"/)          // JSON errors (codex)
          am.askError = am.t("Ошибка агента: ", "Agent error: ") + (msg ? msg[1] : why)
          txt = txt.slice(0, mark)
        }
        am.answer = txt.trim().slice(0, 20000)
      }
    }
    onExited: function(code) {
      am.asking = false
      if (code !== 0 && !am.answer && !am.askError) am.askError = code === 124 ? am.t("Агент не ответил за 3 минуты", "The agent didn't answer in 3 minutes")
                                                               : am.t("Агент завершился с ошибкой (" + code + ")", "The agent failed (" + code + ")")
    }
  }

  // the full agent in a terminal, launched like `omarchy agent` does
  function terminalCommand(id, q) {
    switch (id) {
      case "claude": return ["claude", "--permission-mode", "auto"].concat(q ? ["--", q] : [])
      case "codex": return ["codex", "--approve-for-me"].concat(q ? ["--", q] : [])
      case "gemini": return ["gemini", "--yolo"].concat(q ? ["--prompt-interactive", q] : [])
      case "opencode": return ["opencode", "--auto"].concat(q ? ["--prompt", q] : [])
    }
    return []
  }
  function openInTerminal(q) {
    if (!agent) return
    Quickshell.execDetached(["omarchy-launch-tui", "--app-id=org.omarchy.agent"].concat(terminalCommand(agent, String(q || "").trim())))
    if (notch) notch.expanded = false
  }
  function copy(txt) { Quickshell.execDetached(["wl-copy", String(txt || "")]) }

  // ------------------------------------------------------------ widget
  widgetTitle: t("Лимиты агентов", "Agent limits")
  widgetIcon: "\u{f06a9}"
  widgetPage: Component { AgentsWidgetSettings { mod: am } }
  deskEnabled: opt("widget", false) === true
  function setDeskEnabled(on) { persist({ widget: on }) }
  deskDefault: ({ x: 0.02, y: 0.62 })
  deskWidget: Component { AgentsWidget { mod: am } }
}
