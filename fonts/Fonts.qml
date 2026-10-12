pragma Singleton
import QtQuick
import qs.Commons

// One place for TheNotch's fonts: `ui` for the notch and the settings,
// `desk` for the desktop widgets. Service sets both from Settings →
// Personalisation → Fonts; empty means the system font (Omarchy's
// `omarchy font set`).
QtObject {
  property string uiChoice: ""
  property string deskChoice: ""
  readonly property string ui: uiChoice || Style.font.family
  readonly property string desk: deskChoice || Style.font.family
}
