.pragma library
// TheNotch dashboards, in icon order. Each entry points at a module folder's
// Module.qml; the core knows nothing else about a module. To add a dashboard,
// add a folder with a Module.qml (see modules/README.md) and a line here.
var MODULES = [
  { id: "soundhub", file: "soundhub/Module.qml" },
  { id: "notifications", file: "notifications/Module.qml" },
  { id: "omaloader", file: "omaloader/Module.qml" },
  { id: "quote", file: "quote/Module.qml" },
  { id: "clock", file: "clock/Module.qml" },
  { id: "settings", file: "settings/Module.qml" },
  { id: "modules", file: "modules/Module.qml" },
  { id: "widgets", file: "widgets/Module.qml" },
  { id: "plugins", file: "plugins/Module.qml" }
]
