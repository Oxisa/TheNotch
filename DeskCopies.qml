import QtQuick

// Copies of a module's desktop widget, each with its own settings: a
// gallery of photos next to a gallery of films, say. The main widget keeps
// its settings at the top of the module's options (as before); copies live
// in its `copies` option as [{ wid, title, enabled, ...settings }], with
// wids "<module>:<suffix>". A module puts one of these inside itself and
// binds `deskList: copies.list`. Widgets read their settings with
// cfg(deskId, key, fallback); the Look page edits the widget picked in the
// layout editor (`picked`).
Item {
  id: dc
  property var mod: null                    // the NotchModule
  property Component component: null       // the widget (gets deskId from its window)
  property string icon: ""
  property var defaultPos: ({ x: 0.4, y: 0.4 })
  visible: false

  readonly property string mid: mod ? mod.moduleId : ""
  readonly property var copies: mod && mod.notch ? mod.notch.moduleOpt(mid, "copies", []) : []
  // every instance: the main one first
  readonly property var wids: [mid].concat(copies.map(function(c) { return c.wid }))
  function copyOf(wid) { for (var i = 0; i < copies.length; i++) if (copies[i].wid === wid) return copies[i]; return null }
  function isCopy(wid) { return wid !== mid && copyOf(wid) !== null }

  function cfg(wid, key, fallback) {
    if (!mod || !mod.notch) return fallback
    if (!wid || wid === mid) return mod.notch.moduleOpt(mid, key, fallback)
    var c = copyOf(wid)
    var v = c ? c[key] : undefined
    return v === undefined || v === null ? fallback : v
  }
  function set(wid, values) {
    if (!wid || wid === mid) { mod.notch.modulePersist(mid, values); return }
    var l = JSON.parse(JSON.stringify(copies))
    for (var i = 0; i < l.length; i++) if (l[i].wid === wid) for (var k in values) l[i][k] = values[k]
    mod.notch.modulePersist(mid, { copies: l })
  }

  // the widget whose Look page is open in the layout editor
  readonly property string picked: {
    var p = mod && mod.notch ? mod.notch.layoutPick : ""
    return p === mid || isCopy(p) ? p : mid
  }
  function titleOf(wid) {
    var t = String(cfg(wid, "title", ""))
    if (t) return t
    var n = wids.indexOf(wid)
    return mod.widgetTitle + (n > 0 ? " " + (n + 1) : "")
  }

  // a new copy with the same settings, switched on; returns its wid
  function duplicate(wid) {
    var src = {}, skip = { wid: 1, title: 1, enabled: 1, copies: 1, widget: 1 }
    if (!wid || wid === mid) {
      var all = mod.notch.settings && mod.notch.settings.modules ? (mod.notch.settings.modules[mid] || {}) : {}
      for (var k in all) if (!skip[k]) src[k] = all[k]
    } else {
      var c = copyOf(wid)
      for (var k2 in c) if (!skip[k2]) src[k2] = c[k2]
    }
    src.wid = mid + ":" + Date.now().toString(36)
    src.enabled = true
    mod.notch.modulePersist(mid, { copies: JSON.parse(JSON.stringify(copies)).concat([JSON.parse(JSON.stringify(src))]) })
    return src.wid
  }
  // a copy goes for good, with its place on every monitor
  function remove(wid) {
    if (!isCopy(wid)) return
    if (mod.notch.layoutPick === wid) mod.notch.layoutPick = ""
    mod.notch.modulePersist(mid, { copies: copies.filter(function(c) { return c.wid !== wid }) })
    var l = JSON.parse(JSON.stringify(mod.notch.layout || {}))
    delete l[wid]
    mod.notch.persist({ layout: l })
  }

  // the copies as DeskWidgets for the module's deskList
  property list<QtObject> list
  Instantiator {
    id: inst
    model: dc.copies
    delegate: DeskWidget {
      required property var modelData
      wid: modelData.wid
      title: dc.titleOf(modelData.wid)
      icon: dc.icon
      component: dc.component
      enabled: modelData.enabled !== false
      defaultPos: ({ x: Math.min(0.8, dc.defaultPos.x + 0.04), y: Math.min(0.8, dc.defaultPos.y + 0.04) })
      onToggled: function(on) { dc.set(modelData.wid, { enabled: on }) }
    }
    onObjectAdded: Qt.callLater(dc.rebuild)
    onObjectRemoved: Qt.callLater(dc.rebuild)
  }
  function rebuild() {
    var out = []
    for (var i = 0; i < inst.count; i++) if (inst.objectAt(i)) out.push(inst.objectAt(i))
    list = out
  }
}
