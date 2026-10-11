import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import "../.."
import "../../../osia.soundhub" as SH
import "kronos"
import "kronos/ClockModel.js" as Clock

// Clock: Kronos's orbital/digital desktop clock as a TheNotch widget (a fork
// of MASH2RAFI/omarchy-kronos, MIT — see kronos/README.md for what changed).
// No dashboard; its card is under Settings → Widgets. Settings live in
// modules.clock (seeded once from the Kronos plugin's), and while the Kronos
// plugin itself is on, it draws the clock and this module stays out of the way.
NotchModule {
  id: cm
  readonly property bool ru: notch !== null && notch.lang === "ru"
  title: ru ? "Часы" : "Clock"
  icon: "󰥔"
  description: ru ? "Часы-кольца на рабочем столе (форк Kronos)" : "Orbital desktop clock (a Kronos fork)"
  inRail: false
  widgetTitle: ru ? "Часы на рабочем столе" : "Desktop clock"
  widgetIcon: "󰥔"
  widgetPage: Component { ClockWidget { mod: cm } }

  function opt(key, fallback) { return notch ? notch.moduleOpt("clock", key, fallback) : fallback }
  function persist(values) { if (notch) notch.modulePersist("clock", values) }
  readonly property var entry: notch && notch.settings.modules && notch.settings.modules.clock ? notch.settings.modules.clock : ({})
  readonly property var cfg: Clock.readSettings(entry)

  // first run: start from the Kronos plugin's settings (its bar entry)
  FileView { id: shellJson; path: Quickshell.env("HOME") + "/.config/omarchy/shell.json"; printErrors: false; blockLoading: true }
  readonly property bool canSeed: notch !== null && notch.settingsLoaded
  onCanSeedChanged: {
    if (!canSeed || (notch.settings.modules && notch.settings.modules.clock)) return
    var e = {}
    try {
      var c = JSON.parse(shellJson.text())
      var secs = c.bar && c.bar.layout ? c.bar.layout : {}
      for (var s in secs) for (var i = 0; i < secs[s].length; i++)
        if (secs[s][i] && secs[s][i].id === "mash2rafi.kronos") e = secs[s][i]
    } catch (err) {}
    var v = {}
    for (var k in e) if (k !== "id") v[k] = e[k]
    v.seeded = true
    persist(v)
  }

  // the Kronos plugin draws while it's on; otherwise we do
  readonly property bool kronosOn: notch !== null && notch.pluginEnabled("mash2rafi.kronos")
  readonly property bool draws: active && notch !== null && notch.omarchyPlugins.length > 0 && !kronosOn
                                && cfg.clockEnabled !== false

  // which screens: all, the focused one, or one by name
  readonly property string screenMode: String(opt("screenMode", "all"))
  readonly property string focusedName: Hyprland.focusedMonitor ? String(Hyprland.focusedMonitor.name || "") : ""
  readonly property var screens: {
    var list = Quickshell.screens, out = []
    for (var i = 0; i < list.length; i++) {
      var n = String(list[i].name)
      if (screenMode === "all" || (screenMode === "focused" && n === focusedName) || screenMode === n) out.push(list[i])
    }
    return out
  }

  // bar insets, as Kronos does (the bar may be hidden by the notch; a little
  // extra margin then does no harm)
  readonly property string barPos: notch && notch.shell && notch.shell.barConfig ? String(notch.shell.barConfig.position || "top") : "top"
  readonly property bool barVertical: barPos === "left" || barPos === "right"
  readonly property var insets: Clock.edgeInsets(cfg.position, barPos, barVertical,
                                                  Math.round((barVertical ? Style.bar.sizeVertical : Style.bar.sizeHorizontal) + 14),
                                                  cfg.barPadding)
  readonly property var pos: Clock.parsePosition(cfg.position)

  Variants {
    model: cm.draws ? cm.screens : []
    delegate: PanelWindow {
      id: panel
      required property var modelData
      screen: modelData
      anchors { top: true; bottom: true; left: true; right: true }
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "osia-thenotch-clock"
      WlrLayershell.layer: WlrLayer.Bottom
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      mask: Region {}                                  // click-through: the desktop keeps its clicks
      readonly property var hyprMonitor: Hyprland.monitorFor(modelData)

      Item {
        id: host
        width: face.implicitWidth
        height: face.implicitHeight

        // one placement timer per screen (upstream's single shared timer only
        // ever placed the last screen to ask)
        Timer { id: place; interval: 1; onTriggered: host.placeNow() }
        function relayout() { place.restart() }
        function placeNow() {
          if (panel.width <= 0 || panel.height <= 0) return
          var m = cm.cfg.margin, ins = cm.insets
          var x, y
          if (cm.pos.verticalAlign === "top") y = m + ins.top
          else if (cm.pos.verticalAlign === "bottom") y = panel.height - height - m - ins.bottom
          else y = (panel.height - height) / 2
          if (cm.pos.edgeSide === "center") x = (panel.width - width) / 2
          else if (cm.pos.edgeSide === "right") x = panel.width - width - m - ins.right
          else x = m + ins.left
          var p = Clock.clampPlacement(x, y, width, height, panel.width, panel.height)
          host.x = p.x; host.y = p.y
        }
        Component.onCompleted: relayout()
        onWidthChanged: relayout()
        onHeightChanged: relayout()
        Connections {
          target: panel
          function onWidthChanged() { host.relayout() }
          function onHeightChanged() { host.relayout() }
        }
        Connections {
          target: cm
          function onCfgChanged() { host.relayout() }
          function onInsetsChanged() { host.relayout() }
        }

        ClockFace {
          id: face
          width: implicitWidth
          height: implicitHeight
          active: panel.visible
          availableWidth: panel.width
          availableHeight: panel.height
          screenMargin: cm.cfg.margin
          screenInsets: cm.insets
          scaleFactor: Clock.perMonitorScaleFactor(cm.cfg.scale, panel.height, cm.cfg.perMonitorScale, cm.cfg.scaleReferenceHeight)
          hourScaleFactor: cm.cfg.hourScale
          dateScaleFactor: cm.cfg.dateScale
          subtimeScaleFactor: cm.cfg.subtimeScale
          ringLabelScaleFactor: cm.cfg.ringLabelScale
          minuteCapsuleScaleFactor: cm.cfg.minuteCapsuleScale
          secondCapsuleScaleFactor: cm.cfg.secondCapsuleScale
          screenRefreshRate: Clock.refreshRateForMonitor(panel.hyprMonitor)
          position: cm.cfg.position
          use24h: cm.cfg.use24h
          showSeconds: cm.cfg.showSeconds
          showDate: cm.cfg.showDate
          accentMode: cm.cfg.accentMode
          clockFont: cm.cfg.clockFont
          labelFont: cm.cfg.labelFont
          centerLayout: cm.cfg.centerLayout
          ringDiameter: cm.cfg.ringDiameter
          ringGap: cm.cfg.ringGap
          ringArcDegrees: cm.cfg.ringArcDegrees
          ringTransparency: cm.cfg.ringTransparency
          hourColor: cm.cfg.hourColor
          dateColor: cm.cfg.dateColor
          minuteCapsuleColor: cm.cfg.minuteCapsuleColor
          secondCapsuleColor: cm.cfg.secondCapsuleColor
          minuteRingColor: cm.cfg.minuteRingColor
          secondRingColor: cm.cfg.secondRingColor
          ringLabelColor: cm.cfg.ringLabelColor
          hourFont: cm.cfg.hourFont
          dateFont: cm.cfg.dateFont
          minuteCapsuleFont: cm.cfg.minuteCapsuleFont
          secondCapsuleFont: cm.cfg.secondCapsuleFont
          showHour: cm.cfg.showHour
          showMinuteCapsule: cm.cfg.showMinuteCapsule
          showSecondCapsule: cm.cfg.showSecondCapsule
          showRingLabels: cm.cfg.showRingLabels
          showRings: cm.cfg.showRings
          hourOffsetX: cm.cfg.hourOffsetX
          hourOffsetY: cm.cfg.hourOffsetY
          dateOffsetX: cm.cfg.dateOffsetX
          dateOffsetY: cm.cfg.dateOffsetY
          minuteCapsuleAngleOffset: cm.cfg.minuteCapsuleAngleOffset
          secondCapsuleAngleOffset: cm.cfg.secondCapsuleAngleOffset
          minuteCapsuleRadiusOffset: cm.cfg.minuteCapsuleRadiusOffset
          secondCapsuleRadiusOffset: cm.cfg.secondCapsuleRadiusOffset
          ringRotationOffset: cm.cfg.ringRotationOffset
        }
      }
    }
  }
}
