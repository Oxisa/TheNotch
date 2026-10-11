import QtQuick

// Base for a TheNotch dashboard (modules/<id>/Module.qml). The core sets
// notch / moduleId / order; a module fills in the rest:
//   title, icon           shown on the icon row
//   page, pageWidth       the dashboard (a Component) and its width
//   live, livePriority    "something is going on" — the collapsed notch then
//   liveLeft, liveRight   shows these two ears instead of workspace · clock
//   peek, peekWidth       a card shown on hover while live
// Modules raise events with notch.flash({ key, icon|art, title, message|progress, ms }).
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

  visible: false
}
