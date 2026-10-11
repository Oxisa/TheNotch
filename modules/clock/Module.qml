import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."
import "../../../osia.soundhub" as SH
import "kronos"
import "kronos/ClockModel.js" as Clock
import "../../DeskStyle.js" as DS

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
  // digits: the theme's font, blackletter (the quotes' UnifrakturMaguntia) or a serif
  FontLoader { id: gothic; source: Qt.resolvedUrl("../../../osia.dailyquote/fonts/UnifrakturMaguntia-Book.ttf") }
  readonly property string digitStyle: String(opt("digits", "default"))
  readonly property string digitFont: digitStyle === "gothic" ? gothic.name : digitStyle === "serif" ? "Noto Serif" : ""

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

  // content for TheNotch's widget layer. Where it's put decides which way
  // the rings open: toward the middle of the screen, as Kronos does for its
  // nine positions.
  deskEnabled: !kronosOn && cfg.clockEnabled !== false
  function setDeskEnabled(on) { persist({ clockEnabled: on }) }
  deskDefault: ({ x: 0.80, y: 0.04 })
  deskWidget: Component {
    Item {
      id: w
      property real fx: 0.9
      property real fy: 0.1
      property real screenW: 1920
      property real screenH: 1080
      property bool editing: false
      property bool deskVertical: false              // turned 90°: digits stack, no tilt
      readonly property bool deskShown: true
      readonly property string zone: (fy < 0.34 ? "top" : fy > 0.66 ? "bottom" : "middle") + "-"
                                     + (fx < 0.34 ? "left" : fx > 0.66 ? "right" : "center")
      readonly property string look: String(cm.opt("style", "kronos"))   // kronos | type | flip | day
      // a card behind the clock, like the other widgets (0 = none, as before)
      property var deskStyle: ({})
      property real deskScale: 1                    // the layout's scale, drawn natively (no blurry rings)
      readonly property real bgAlpha: Number(DS.pick(deskStyle, "bgOpacity", cm.opt("bgOpacity", 0)))
      readonly property real pad: bgAlpha > 0 ? Style.space(18) * deskScale : 0
      width: (look === "kronos" ? face.implicitWidth : styles.width) + pad * 2
      height: (look === "kronos" ? face.implicitHeight : styles.height) + pad * 2
      Rectangle {
        anchors.fill: parent
        visible: w.bgAlpha > 0
        radius: DS.radius(w.deskStyle, Style.space(18))
        topLeftRadius: DS.corner(w.deskStyle, "tl", Style.space(18))
        topRightRadius: DS.corner(w.deskStyle, "tr", Style.space(18))
        bottomLeftRadius: DS.corner(w.deskStyle, "bl", Style.space(18))
        bottomRightRadius: DS.corner(w.deskStyle, "br", Style.space(18))
        color: DS.bg(w.deskStyle, Color.background, Color.accent, w.bgAlpha)
        border.width: 1
        border.color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.08)
      }
      ClockStyles {
        id: styles
        x: w.pad; y: w.pad
        digitFont: cm.digitFont
        visible: w.look !== "kronos"
        look: w.look === "kronos" ? "type" : w.look
        use24h: cm.cfg.use24h
        showDate: cm.cfg.showDate
        size: cm.cfg.scale * w.deskScale
        ru: cm.ru
        vertical: w.deskVertical
      }
    ClockFace {
      id: face
      x: w.pad; y: w.pad
      visible: w.look === "kronos"
      width: implicitWidth
      height: implicitHeight
      active: true
      availableWidth: w.screenW
      availableHeight: w.screenH
      screenMargin: cm.cfg.margin
      screenInsets: ({ top: 0, right: 0, bottom: 0, left: 0 })
      scaleFactor: Clock.perMonitorScaleFactor(cm.cfg.scale, w.screenH, cm.cfg.perMonitorScale, cm.cfg.scaleReferenceHeight) * w.deskScale
      hourScaleFactor: cm.cfg.hourScale
      dateScaleFactor: cm.cfg.dateScale
      subtimeScaleFactor: cm.cfg.subtimeScale
      ringLabelScaleFactor: cm.cfg.ringLabelScale
      minuteCapsuleScaleFactor: cm.cfg.minuteCapsuleScale
      secondCapsuleScaleFactor: cm.cfg.secondCapsuleScale
      screenRefreshRate: 60
      position: w.zone
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
      hourFont: cm.digitFont || cm.cfg.hourFont
      dateFont: cm.digitFont || cm.cfg.dateFont
      minuteCapsuleFont: cm.digitFont || cm.cfg.minuteCapsuleFont
      secondCapsuleFont: cm.digitFont || cm.cfg.secondCapsuleFont
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
