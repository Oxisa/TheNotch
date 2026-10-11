import QtQuick

// One extra desktop widget a module offers (besides its main deskWidget):
// modules list these in `deskList`. Same contract as the main one.
QtObject {
  property string wid: ""
  property string title: ""
  property string icon: ""
  property Component component: null
  property bool enabled: false
  property var defaultPos: ({ x: 0.04, y: 0.08 })
  signal toggled(bool on)
}
