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

  // a tab on top of the open notch (Home, Sound, System, Centre); the other
  // dashboards are small icons at the right end of the tab row
  property bool topTab: false
  // shown inside another tab (Notifications in Centre): no icon of its own
  property bool noIcon: false

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
  // The widget itself: content only — TheNotch owns the windows, positions
  // and the per-monitor layout (WidgetWindow / LayoutEditor). The content may
  // declare fx, fy (its centre as a share of the screen), screenW, screenH
  // and editing; the host fills them in. `deskShown: false` hides it (e.g. no
  // track), except while the layout is being edited.
  property Component deskWidget: null
  property bool deskEnabled: false
  property var deskDefault: ({ x: 0.04, y: 0.08 })   // where it first lands, as a share of the screen
  function setDeskEnabled(on) {}
  // more widgets from the same module (DeskWidget objects), e.g. Sound's visualizer
  property list<QtObject> deskList

  // a short text the collapsed notch shows next to its clock (e.g. "☁ +12°")
  property string ear: ""

  visible: false
}
