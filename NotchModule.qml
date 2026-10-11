import QtQuick

// Base for a TheNotch dashboard (modules/<id>/Module.qml). The core sets
// notch / moduleId / order; a module fills in the rest:
//   title, icon           shown on the icon row
//   page, pageWidth       the dashboard (a Component) and its width
//   live, livePriority    "something is going on" — the collapsed notch then
//   liveLeft, liveRight   shows these two ears instead of workspace · clock
//   peek, peekWidth       a card shown on hover while live
//   settingsPage          its section in the settings window (gear on the
//                         icon row); `inRail: false` for settings-only modules
//   widgetPage            its desktop widget's card in Settings → Widgets
//   core / active         core sections can't be switched off; `active` is
//                         the on/off from Settings → Modules
// Modules raise events with notch.flash({ key, icon|iconSource|art, title,
// message|progress, ms, big, hold, action(), dismiss(), onHold(bool) }) and
// take them back with notch.removeEvent(key).
Item {
  property var notch: null
  property string moduleId: ""
  property int order: 0

  property string title: ""
  property string icon: "󰋼"

  property Component page: null
  property int pageWidth: 440

  property bool live: false
  property int livePriority: 0
  property Component liveLeft: null
  property Component liveRight: null

  property Component peek: null
  property int peekWidth: 380

  property Component settingsPage: null
  property bool inRail: true
  property int sectionOrder: 50            // place in the settings sidebar

  // On/off from Settings → Modules. Core sections (Modules, Widgets…) can't
  // be switched off. A switched-off module leaves the icon row, shows no
  // live view or events, and its widget is greyed out.
  property bool core: false
  property string description: ""
  readonly property bool active: core || !notch || notch.moduleOpt(moduleId, "enabled", true) !== false

  // its desktop widget, for Settings → Widgets
  property Component widgetPage: null
  property string widgetTitle: ""
  property string widgetIcon: ""

  visible: false
}
