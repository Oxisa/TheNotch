import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import qs.Commons
import "../../vendor/soundhub" as SH
import "../home"
import "../../fonts"

// Centre as a control centre (after macOS and GNOME): big tiles for the
// network and Bluetooth, small ones for switches, sliders for sound, the
// microphone and brightness, tools, and the notifications folded
// at the bottom. A tile's › opens its short list right below the row
// (connect a network or a device, pick an output) — the full pages stay in
// Settings. Everything comes from the modules that own it.
Row {
  id: page
  property var mod: null
  spacing: Style.space(12)
  readonly property real colW: (width - spacing) / 2
  readonly property color fg: Color.foreground
  readonly property color accent: Color.accent
  readonly property color bgc: Color.background
  readonly property string ff: Fonts.ui
  function t(a, b) { return mod ? mod.t(a, b) : b }
  function m(id) { return mod ? mod.moduleById(id) : null }
  readonly property var nw: m("network")
  readonly property var dv: m("devices")
  readonly property var dm: m("displays")
  readonly property var snd: m("soundhub")
  readonly property var pv: m("privacy")
  readonly property var notif: mod ? mod.notif : null
  readonly property real gap: Style.space(8)
  property string open: ""                        // the tile whose list is shown (left column)
  // the Wi-Fi list is on screen: let NetworkManager scan (live list)
  Binding { target: page.nw; property: "wantScan"; value: page.open === "net" && page.visible; when: page.nw !== null }
  property bool notifOpen: false
  property bool timerOpen: false
  function toggleOpen(id) { open = open === id ? "" : id }

  // fresh states while the centre is on screen
  Timer {
    interval: 10000; repeat: true; triggeredOnStart: true; running: page.visible
    onTriggered: {
      if (page.nw && page.nw.active) page.nw.cmd(["status"])
    }
  }
  Component.onCompleted: if (dm && dm.active) dm.refresh()

  // ---------------------------------------------------------------- tiles
  component BigTile: Rectangle {
    id: bt
    property string glyph: ""
    property string label: ""
    property string sub: ""
    property bool on: false
    property string listId: ""
    signal toggled()
    width: (page.colW - page.gap) / 2; height: Style.space(58)
    radius: Style.space(16)
    color: SH.HubStyle.tint(page.fg, bm.containsMouse ? 0.10 : 0.06)
    border.width: page.open === listId && listId ? 1 : 0; border.color: page.accent
    Rectangle {
      id: dot
      x: Style.space(10); anchors.verticalCenter: parent.verticalCenter
      width: Style.space(38); height: width; radius: width / 2
      color: bt.on ? page.accent : SH.HubStyle.tint(page.fg, 0.10)
      Text { anchors.centerIn: parent; text: bt.glyph; color: bt.on ? page.bgc : page.fg; font.family: page.ff; font.pixelSize: Style.space(18) }
      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bt.toggled() }
    }
    Column {
      anchors.left: dot.right; anchors.leftMargin: Style.space(10)
      anchors.right: chev.left; anchors.verticalCenter: parent.verticalCenter
      Text { width: parent.width; elide: Text.ElideRight; text: bt.label; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.body; font.bold: true }
      Text { width: parent.width; elide: Text.ElideRight; text: bt.sub; color: Qt.darker(page.fg, 1.5); font.family: page.ff; font.pixelSize: Style.font.caption - 1 }
    }
    Text {
      id: chev
      visible: !!bt.listId
      anchors.right: parent.right; anchors.rightMargin: Style.space(12); anchors.verticalCenter: parent.verticalCenter
      text: page.open === bt.listId ? "\u{f0143}" : "\u{f0142}"
      color: Qt.darker(page.fg, 1.3); font.family: page.ff; font.pixelSize: Style.font.body + 2
    }
    MouseArea {
      id: bm
      anchors.fill: parent; anchors.leftMargin: dot.width + Style.space(10)
      hoverEnabled: true; cursorShape: Qt.PointingHandCursor
      onClicked: bt.listId ? page.toggleOpen(bt.listId) : bt.toggled()
    }
  }
  component SmallTile: Rectangle {
    id: st
    property string glyph: ""
    property string label: ""
    property bool on: false
    property color tone: page.accent
    signal clicked()
    width: (page.colW - page.gap * 3) / 4; height: Style.space(64)
    radius: Style.space(16)
    color: on ? SH.HubStyle.tint(tone, sm.containsMouse ? 0.42 : 0.30) : SH.HubStyle.tint(page.fg, sm.containsMouse ? 0.10 : 0.06)
    Behavior on color { ColorAnimation { duration: 150 } }
    Column {
      anchors.centerIn: parent
      width: parent.width - Style.space(8)
      spacing: Style.space(4)
      Text { anchors.horizontalCenter: parent.horizontalCenter; text: st.glyph; color: st.on ? st.tone : page.fg; font.family: page.ff; font.pixelSize: Style.space(18) }
      Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: st.label; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption - 2 }
    }
    MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: st.clicked() }
  }
  component ToolTipText: Rectangle {
    property alias text: tt.text
    anchors.bottom: parent.top; anchors.bottomMargin: Style.space(4); anchors.horizontalCenter: parent.horizontalCenter
    width: tt.implicitWidth + Style.space(12); height: Style.space(22); radius: Style.space(6)
    color: Qt.rgba(0, 0, 0, 0.85); z: 10
    Text { id: tt; anchors.centerIn: parent; color: "white"; font.family: page.ff; font.pixelSize: Style.font.caption - 1 }
  }
  // a row in a tile's list
  component ListRow: Rectangle {
    id: lr
    property string glyph: ""
    property string label: ""
    property string sub: ""
    property bool on: false
    property bool working: false
    signal clicked()
    width: parent ? parent.width : 0; height: Style.space(38)
    radius: Style.space(10)
    color: lm.containsMouse ? SH.HubStyle.tint(page.fg, 0.08) : "transparent"
    Text { x: Style.space(10); anchors.verticalCenter: parent.verticalCenter; text: lr.glyph; color: lr.on ? page.accent : page.fg; font.family: page.ff; font.pixelSize: Style.font.body + 1 }
    Text {
      x: Style.space(38); anchors.verticalCenter: parent.verticalCenter
      width: parent.width - Style.space(48) - subT.implicitWidth; elide: Text.ElideRight
      text: lr.label; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption + 1; font.bold: lr.on
    }
    // extra actions show on hover: [{ glyph, label, run() }]; one marked
    // `confirm` asks again before it runs (forget a device)
    property var actions: []
    property int armed: -1
    Text { id: subT; anchors.right: parent.right; anchors.rightMargin: Style.space(10); anchors.verticalCenter: parent.verticalCenter
           visible: !(lm.containsMouse && lr.actions.length)
           text: lr.working ? "…" : lr.sub; color: lr.on ? page.accent : Qt.darker(page.fg, 1.5); font.family: page.ff; font.pixelSize: Style.font.caption - 1 }
    MouseArea { id: lm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: lr.clicked(); onContainsMouseChanged: if (!containsMouse) lr.armed = -1 }
    Row {
      visible: lm.containsMouse && lr.actions.length > 0
      anchors.right: parent.right; anchors.rightMargin: Style.space(6); anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(4)
      Repeater {
        model: lr.actions
        delegate: Rectangle {
          required property var modelData
          required property int index
          readonly property bool asking: lr.armed === index
          width: asking ? askT.implicitWidth + Style.space(16) : height; height: Style.space(26); radius: height / 2
          color: asking ? Color.urgent : SH.HubStyle.tint(page.fg, am.containsMouse ? 0.16 : 0.08)
          Text { id: askT; anchors.centerIn: parent; text: parent.asking ? page.t("Точно?", "Sure?") : modelData.glyph; color: parent.asking ? page.bgc : page.fg; font.family: page.ff; font.pixelSize: Style.font.caption }
          MouseArea {
            id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: { if (modelData.confirm && lr.armed !== index) { lr.armed = index; return } lr.armed = -1; modelData.run() }
          }
          ToolTipText { visible: am.containsMouse && !parent.asking; text: modelData.label }
        }
      }
    }
  }
  component ListBox: Rectangle {
    id: box
    default property alias content: col.data
    property string title: ""
    property string settingsId: ""
    width: page.colW
    height: col.implicitHeight + Style.space(16)
    radius: Style.space(16)
    color: SH.HubStyle.tint(page.fg, 0.04)
    Column {
      id: col
      x: Style.space(8); y: Style.space(8)
      width: parent.width - Style.space(16)
      spacing: Style.space(2)
      Item {
        width: parent.width; height: Style.space(26)
        Text { x: Style.space(10); anchors.verticalCenter: parent.verticalCenter; text: box.title; color: Qt.darker(page.fg, 1.3); font.family: page.ff; font.pixelSize: Style.font.caption; font.bold: true }
        Text {
          visible: !!box.settingsId
          anchors.right: parent.right; anchors.rightMargin: Style.space(10); anchors.verticalCenter: parent.verticalCenter
          text: page.t("Настройки…", "Settings…"); color: page.accent; font.family: page.ff; font.pixelSize: Style.font.caption
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.mod.notch.openSettings(box.settingsId) }
        }
      }
    }
  }

  // ---------------------------------------------------- network + bluetooth
  readonly property var sys: mod ? mod.sys : ({})
  readonly property bool hasWifi: mod.wifiState === "enabled" || mod.wifiState === "disabled"
  readonly property var btDevices: dv && dv.st.devices ? dv.st.devices.filter(function(d) { return d.paired }) : []
  readonly property var btConnected: btDevices.filter(function(d) { return d.connected })

  // ------------------------------------------------------------ switches
  readonly property var hph: m("headphones")

  // ------------------------------------------------------------- sliders
  // the physical sink behind SoundHub's EQ carries the volume
  property string volumeSinkName: ""
  Process { id: volumeProc; command: ["omarchy-audio-output-sink"]; stdout: StdioCollector { waitForEnd: true; onStreamFinished: page.volumeSinkName = String(text).trim() } }
  Timer { interval: 5000; repeat: true; triggeredOnStart: true; running: page.visible; onTriggered: if (!volumeProc.running) volumeProc.running = true }
  readonly property var nodes: Pipewire.nodes ? Pipewire.nodes.values : []
  readonly property var sinks: uniq(nodes.filter(function(n) { return n && n.isSink && !n.isStream && n.audio && /^(alsa|bluez)_output/.test(String(n.name)) }), Pipewire.defaultAudioSink)
  // one row per device: some expose two nodes with the same name (mono fallback)
  function uniq(list, cur) { var seen = {}, out = []; list.forEach(function(n) { var k = nameOf(n); if (!seen[k]) { seen[k] = out.length; out.push(n) } else if (n === cur) out[seen[k]] = n }); return out }
  readonly property var sources: uniq(nodes.filter(function(n) { return n && !n.isSink && !n.isStream && n.audio && /^(alsa|bluez)_input/.test(String(n.name)) }), Pipewire.defaultAudioSource)
  readonly property var sink: { for (var i = 0; i < sinks.length; i++) if (String(sinks[i].name) === volumeSinkName) return sinks[i]; return Pipewire.defaultAudioSink }
  readonly property var source: Pipewire.defaultAudioSource
  PwObjectTracker { objects: [page.sink, page.source].concat(page.sinks).concat(page.sources) }
  function nameOf(n) { return n ? String(n.description || n.nickname || n.name) : "" }
  function setOutput(node) {
    if (snd && typeof snd.selectOutput === "function" && snd.selectOutput(node)) return
    Pipewire.preferredDefaultAudioSink = node
    Quickshell.execDetached(["omarchy-audio-output-set-default", String(node.id), String(node.name)])
  }
  function setInput(node) {
    Pipewire.preferredDefaultAudioSource = node
    Quickshell.execDetached(["omarchy-audio-input-set-default", String(node.id), String(node.name)])
  }
  readonly property var shownDisplays: dm && dm.active ? dm.displays.filter(function(d) { return (dm.brightness[d.name] || -1) >= 0 }) : []
  readonly property real brightAvg: { var s = 0; for (var i = 0; i < shownDisplays.length; i++) s += dm.brightness[shownDisplays[i].name]; return shownDisplays.length ? s / shownDisplays.length : 0 }

  component SliderRow: Item {
    id: sr
    property string glyph: ""
    property real value: 0
    property string chip: ""
    property string listId: ""
    property color dotColor: "transparent"
    signal glyphClicked()
    signal moved(real v)
    signal released(real v)
    width: page.colW; height: Style.space(34)
    Text {
      id: g
      width: Style.space(24); anchors.verticalCenter: parent.verticalCenter
      text: sr.glyph; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.body + 3
      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: sr.glyphClicked() }
      Rectangle { visible: sr.dotColor.a > 0; anchors.right: parent.right; anchors.top: parent.top; anchors.rightMargin: Style.space(2); width: Style.space(7); height: width; radius: width / 2; color: sr.dotColor }
    }
    SH.HubSlider {
      anchors.left: g.right; anchors.leftMargin: Style.space(8)
      anchors.right: chipBox.left; anchors.rightMargin: Style.space(10)
      anchors.verticalCenter: parent.verticalCenter
      value: sr.value
      trackHeight: Style.space(6); knobSize: Style.space(14)
      onMoved: function(v) { sr.moved(v) }
      onReleased: function(v) { sr.released(v) }
    }
    Rectangle {
      id: chipBox
      visible: !!sr.chip
      anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
      width: Math.min(Style.space(150), chipT.implicitWidth + Style.space(28)); height: Style.space(26); radius: height / 2
      color: page.open === sr.listId ? SH.HubStyle.tint(page.accent, 0.3) : SH.HubStyle.tint(page.fg, cm.containsMouse ? 0.12 : 0.06)
      Text { id: chipT; x: Style.space(10); width: parent.width - Style.space(26); anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; text: sr.chip; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption - 1 }
      Text { anchors.right: parent.right; anchors.rightMargin: Style.space(8); anchors.verticalCenter: parent.verticalCenter; text: "\u{f0142}"; color: Qt.darker(page.fg, 1.3); font.family: page.ff; font.pixelSize: Style.font.caption }
      MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.toggleOpen(sr.listId) }
    }
  }

  // --------------------------------------------------------------- tools
  readonly property var tools: {
    var out = [{ id: "timer", glyph: "\u{f051b}", label: page.t("Таймер", "Timer"), on: page.timerOpen || (page.mod && (page.mod.timerRunning || page.mod.swRunning || page.mod.phase !== "idle")) }]
    var ms = page.mod && page.mod.notch ? page.mod.notch.iconModules : []
    for (var i = 0; i < ms.length; i++) out.push({ id: "m:" + ms[i].moduleId, glyph: ms[i].icon, label: ms[i].title, on: false })
    out.push({ id: "rec", glyph: "\u{f044b}", label: page.t("Запись экрана", "Recording"), on: !!page.sys.rec })
    return out
  }

  // ------------------------------------------------------- notifications
  readonly property int notifCount: notif && notif.history ? notif.history.length : 0
  Column {
    id: leftCol
    width: page.colW
    spacing: Style.space(10)
  Flow {
    width: page.colW
    spacing: page.gap
    BigTile {
      glyph: page.nw ? page.nw.glyph : "\u{f0200}"
      label: page.nw && page.nw.onWifi || page.mod.wifiState === "enabled" ? "Wi-Fi" : page.t("Сеть", "Network")
      sub: page.nw ? page.nw.name : ""
      on: page.nw ? page.nw.online : false
      listId: "net"
      // the circle only switches Wi-Fi off; on a cable it just opens the list
      onToggled: if (page.mod.wifiState === "enabled") page.mod.toggle("wifi"); else page.toggleOpen("net")
    }
    BigTile {
      glyph: page.mod.btOn ? "\u{f00af}" : "\u{f00b2}"
      label: "Bluetooth"
      sub: !page.mod.btOn ? page.t("Выключен", "Off") : page.btConnected.length
           ? page.btConnected.map(function(d) { return d.name + (d.battery !== null && d.battery !== undefined ? " " + d.battery + "%" : "") }).join(", ")
           : page.t("Нет подключений", "Not connected")
      on: !!page.mod.btOn
      listId: "bt"
      onToggled: page.mod.toggle("bt")
    }
  }
  ListBox {
    visible: page.open === "net"
    title: page.hasWifi && page.mod.wifiState === "enabled" ? page.t("Сети Wi-Fi", "Wi-Fi networks") : page.t("Подключения", "Connections")
    settingsId: "network"
    Repeater {
      model: page.nw && page.hasWifi && page.mod.wifiState === "enabled" ? page.nw.networks.slice(0, 8) : []
      delegate: ListRow {
        required property var modelData
        glyph: page.nw.wifiGlyph(modelData.signal)
        label: modelData.ssid
        sub: modelData.active ? page.t("подключено", "connected") : (modelData.secure && !modelData.saved ? "\u{f033e}" : "")
        on: modelData.active
        working: page.nw.busy.indexOf(modelData.ssid) >= 0
        // a new secured network needs a password: that's the settings page's job
        onClicked: if (!modelData.active) { if (modelData.secure && !modelData.saved) page.mod.notch.openSettings("network"); else page.nw.connect(modelData.ssid) }
      }
    }
    Repeater {
      model: page.nw ? page.nw.saved.filter(function(s) { return s.type === "ethernet" || (s.type === "wifi" && !(page.hasWifi && page.mod.wifiState === "enabled")) || s.active }).slice(0, 6) : []
      delegate: ListRow {
        required property var modelData
        visible: !(page.hasWifi && page.mod.wifiState === "enabled" && modelData.type === "wifi")
        glyph: modelData.type === "wifi" ? "\u{f05a9}" : modelData.type === "ethernet" ? "\u{f0200}" : "\u{f00af}"
        label: modelData.name
        sub: modelData.active ? page.t("подключено", "connected") : ""
        on: modelData.active
        onClicked: if (!modelData.active) page.nw.connect(modelData.name)
      }
    }
  }
  ListBox {
    visible: page.open === "bt"
    title: page.t("Устройства", "Devices")
    settingsId: "bluetooth"
    Repeater {
      model: page.btDevices
      delegate: ListRow {
        required property var modelData
        glyph: page.dv.glyph(modelData.kind)
        label: modelData.name
        sub: modelData.connected ? (modelData.battery !== null && modelData.battery !== undefined ? modelData.battery + "%" : page.t("подключено", "connected")) : ""
        on: modelData.connected
        working: page.dv.busy.indexOf(modelData.mac) >= 0
        onClicked: page.dv.bt(modelData.connected ? "disconnect" : "connect", modelData.mac)
        actions: [
          { glyph: modelData.connected ? "\u{f00b2}" : "\u{f00b1}", label: modelData.connected ? page.t("Отключить", "Disconnect") : page.t("Подключить", "Connect"),
            run: function() { page.dv.bt(modelData.connected ? "disconnect" : "connect", modelData.mac) } },
          { glyph: "\u{f0493}", label: page.t("Настройки устройства", "Device settings"), run: function() { page.mod.notch.openSettings("devices") } },
          { glyph: "\u{f0a7a}", label: page.t("Забыть устройство", "Forget the device"), confirm: true, run: function() { page.dv.bt("remove", modelData.mac) } }
        ]
      }
    }
    ListRow {
      glyph: "\u{f0415}"
      label: page.dv && page.dv.scanning ? page.t("Ищу устройства…", "Searching…") : page.t("Добавить устройство", "Add a device")
      onClicked: { page.dv.scan(); page.mod.notch.openSettings("devices") }
    }
    Text { visible: !page.btDevices.length; x: Style.space(10); text: page.t("Нет сопряжённых устройств", "No paired devices"); color: Qt.darker(page.fg, 1.6); font.family: page.ff; font.pixelSize: Style.font.caption }
  }
  Flow {
    width: page.colW
    spacing: page.gap
    SmallTile { glyph: page.notif && page.notif.dnd ? "\u{f009b}" : "\u{f009a}"; label: page.t("Не беспокоить", "Do not disturb"); on: !!(page.notif && page.notif.dnd); onClicked: page.mod.toggle("dnd") }
    SmallTile { glyph: "\u{f0594}"; label: page.t("Ночной свет", "Night light"); on: !!page.sys.night; onClicked: page.mod.toggle("night") }
    SmallTile { glyph: "\u{f0176}"; label: page.t("Не засыпать", "Stay awake"); on: !!page.sys.awake; onClicked: page.mod.toggle("awake") }
    SmallTile {
      visible: page.hph !== null && page.hph.active && page.hph.present
      glyph: page.hph ? page.hph.modeIcon(page.hph.mode) : ""
      label: page.hph ? page.hph.modeName(page.hph.mode) : ""
      on: page.hph !== null && page.hph.mode !== "off"
      onClicked: page.mod.toggle("hp")
    }
  }
  Rectangle {
    width: page.colW
    height: sliders.implicitHeight + Style.space(16)
    radius: Style.space(16)
    color: SH.HubStyle.tint(page.fg, 0.06)
    Column {
      id: sliders
      x: Style.space(12); y: Style.space(8)
      width: parent.width - Style.space(24)
      // the full Sound page (now playing, EQ, focus sounds, microphone)
      Item {
        width: parent.width; height: Style.space(24)
        Text { anchors.verticalCenter: parent.verticalCenter; text: page.t("Звук", "Sound"); color: Qt.darker(page.fg, 1.3); font.family: page.ff; font.pixelSize: Style.font.caption; font.bold: true }
        Text {
          anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
          text: page.t("Эквалайзер, фокус, микрофон  \u{f0142}", "EQ, focus, microphone  \u{f0142}")
          color: sndM.containsMouse ? page.fg : page.accent; font.family: page.ff; font.pixelSize: Style.font.caption
          MouseArea { id: sndM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.mod.notch.openModule("soundhub") }
        }
      }
      SliderRow {
        width: parent.width
        readonly property bool muted: !!(page.sink && page.sink.audio && page.sink.audio.muted)
        glyph: muted ? "\u{f075f}" : "\u{f057e}"
        value: page.sink && page.sink.audio ? page.sink.audio.volume : 0
        chip: page.nameOf(page.sink)
        listId: "out"
        onGlyphClicked: if (page.sink && page.sink.audio) page.sink.audio.muted = !page.sink.audio.muted
        onMoved: function(v) { if (page.sink && page.sink.audio) page.sink.audio.volume = v }
      }
      SliderRow {
        width: parent.width
        readonly property bool muted: !!(page.source && page.source.audio && page.source.audio.muted)
        glyph: muted ? "\u{f036d}" : "\u{f036c}"
        value: page.source && page.source.audio ? page.source.audio.volume : 0
        chip: page.nameOf(page.source)
        listId: "in"
        dotColor: page.pv && page.pv.mic.length ? page.pv.micColor : "transparent"
        onGlyphClicked: page.mod.toggle("mic")
        onMoved: function(v) { if (page.source && page.source.audio) page.source.audio.volume = v }
      }
      SliderRow {
        width: parent.width
        visible: page.shownDisplays.length > 0
        glyph: "\u{f00e0}"
        value: page.brightAvg / 100
        chip: page.shownDisplays.length > 1 ? page.t("Все мониторы", "All monitors") : (page.shownDisplays.length ? page.shownDisplays[0].name : "")
        listId: "bright"
        onReleased: function(v) { for (var i = 0; i < page.shownDisplays.length; i++) page.dm.cmd(["brightness", page.shownDisplays[i].name, String(Math.max(1, Math.round(v * 100)))]) }
      }
    }
  }
  ListBox {
    visible: page.open === "out"
    title: page.t("Вывод звука", "Sound output")
    settingsId: "sound"
    Repeater {
      model: page.sinks
      delegate: ListRow {
        required property var modelData
        glyph: /bluez/.test(String(modelData.name)) ? "\u{f02cb}" : "\u{f04c3}"
        label: page.nameOf(modelData)
        on: page.sink === modelData
        sub: on ? "\u{f012c}" : ""
        onClicked: page.setOutput(modelData)
      }
    }
  }
  ListBox {
    visible: page.open === "in"
    title: page.t("Микрофон", "Microphone")
    settingsId: "sound"
    Repeater {
      model: page.sources
      delegate: ListRow {
        required property var modelData
        glyph: "\u{f036c}"
        label: page.nameOf(modelData)
        on: page.source === modelData
        sub: on ? "\u{f012c}" : ""
        onClicked: page.setInput(modelData)
      }
    }
    // who is listening right now (Privacy)
    Repeater {
      model: page.pv ? page.pv.mic : []
      delegate: Row {
        required property var modelData
        x: Style.space(10); height: Style.space(28); spacing: Style.space(8)
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Style.space(8); height: width; radius: width / 2; color: page.pv.micColor }
        IconImage { anchors.verticalCenter: parent.verticalCenter; width: Style.space(18); height: width; source: page.pv.iconOf(modelData) }
        Text { anchors.verticalCenter: parent.verticalCenter; text: page.pv.nameOf(modelData) + page.t(" слушает микрофон", " is listening"); color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption }
      }
    }
  }
  ListBox {
    visible: page.open === "bright"
    title: page.t("Яркость мониторов", "Monitor brightness")
    settingsId: "displays"
    Repeater {
      model: page.shownDisplays
      delegate: Item {
        required property var modelData
        width: parent.width; height: Style.space(34)
        Text { x: Style.space(10); width: Style.space(60); anchors.verticalCenter: parent.verticalCenter; text: modelData.name; color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption }
        SH.HubSlider {
          x: Style.space(76); width: parent.width - Style.space(86); anchors.verticalCenter: parent.verticalCenter
          value: (page.dm.brightness[modelData.name] || 0) / 100
          onReleased: function(v) { page.dm.cmd(["brightness", modelData.name, String(Math.max(1, Math.round(v * 100)))]) }
        }
      }
    }
  }

  }
  Column {
    id: rightCol
    width: page.colW
    spacing: Style.space(10)
  Flow {
    width: page.colW
    spacing: page.gap
    Repeater {
      model: page.tools
      delegate: SmallTile {
        required property var modelData
        glyph: modelData.glyph; label: modelData.label; on: modelData.on
        onClicked: {
          var id = modelData.id
          if (id === "timer") page.timerOpen = !page.timerOpen
          else if (id === "rec") page.mod.toggle("rec")
          else if (id === "m:screenshot") page.mod.toggle("shot")
          else page.mod.notch.openModule(id.slice(2))
        }
      }
    }
  }
  Rectangle {
    visible: page.timerOpen
    width: page.colW
    height: timer.implicitHeight + Style.space(24)
    radius: Style.space(16)
    color: SH.HubStyle.tint(page.fg, 0.04)
    TimerCard { id: timer; anchors.centerIn: parent; mod: page.mod }
  }
  Rectangle {
    visible: !!(page.notif && page.notif.active)
    width: page.colW; height: Style.space(40)
    radius: Style.space(14)
    color: SH.HubStyle.tint(page.fg, nm.containsMouse ? 0.10 : 0.06)
    Text { x: Style.space(14); anchors.verticalCenter: parent.verticalCenter; text: "\u{f009a}   " + page.t("Уведомления", "Notifications") + (page.notifCount ? " · " + page.notifCount : ""); color: page.fg; font.family: page.ff; font.pixelSize: Style.font.caption + 1; font.bold: true }
    Text { anchors.right: parent.right; anchors.rightMargin: Style.space(14); anchors.verticalCenter: parent.verticalCenter; text: page.notifOpen ? "\u{f0143}" : "\u{f0140}"; color: Qt.darker(page.fg, 1.3); font.family: page.ff; font.pixelSize: Style.font.body + 2 }
    MouseArea { id: nm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.notifOpen = !page.notifOpen }
  }
  Item {
    visible: page.notifOpen
    width: page.colW
    height: Math.min(Style.space(420), notifLoader.item ? notifLoader.item.implicitHeight : 0)
    clip: true
    Flickable {
      anchors.fill: parent
      contentHeight: notifLoader.item ? notifLoader.item.implicitHeight : 0
      interactive: contentHeight > height
      boundsBehavior: Flickable.StopAtBounds
      Loader {
        id: notifLoader
        width: page.colW
        active: page.notifOpen && !!(page.notif && page.notif.active && page.notif.page)
        sourceComponent: page.notif ? page.notif.page : null
      }
    }
  }
  }
}
