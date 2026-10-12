import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../.."
import "../../vendor/soundhub" as SH

// Weather: the current weather for a city you pick, from Open-Meteo (no key,
// no account). A desktop widget in one of three looks — capsule, card or a
// single line — and, if you like, the temperature in the collapsed notch next
// to the clock. Looks after the weather styles of rover-001/whimsy (MIT);
// no code taken.
NotchModule {
  id: wm
  readonly property bool ru: notch !== null && notch.lang === "ru"
  function t(a, b) { return ru ? a : b }
  title: t("Погода", "Weather")
  icon: "\u{f0595}"
  description: t("Погода в выбранном городе — виджетом и в свёрнутой чёлке (Open-Meteo)",
                 "The weather in your city — as a widget and in the collapsed notch (Open-Meteo)")
  inRail: false
  sectionOrder: 14
  function opt(key, fallback) { return notch ? notch.moduleOpt("weather", key, fallback) : fallback }
  function persist(values) { if (notch) notch.modulePersist("weather", values) }
  settingsPage: Component { WeatherSettings { mod: wm } }

  readonly property var place: opt("place", null)              // { name, country, lat, lon }
  readonly property string look: String(opt("look", "capsule"))  // capsule | card | line
  readonly property bool inNotch: opt("inNotch", true) === true

  // ------------------------------------------------------------ fetching
  property var now: null                                         // { temp, feels, code, wind, hum, day, hi, lo }
  property string error: ""
  readonly property bool wanted: active && place !== null && (deskEnabled || inNotch)
  Process {
    id: fetch
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var d = JSON.parse(text), c = d.current
          wm.now = { temp: c.temperature_2m, feels: c.apparent_temperature, code: c.weather_code, wind: c.wind_speed_10m,
                     hum: c.relative_humidity_2m, day: c.is_day === 1,
                     hi: d.daily ? d.daily.temperature_2m_max[0] : null, lo: d.daily ? d.daily.temperature_2m_min[0] : null,
                     hours: wm.nextHours(d) }
          wm.error = ""
        } catch (e) { wm.error = wm.t("Нет данных о погоде", "No weather data") }
      }
    }
  }
  // the next four hours (the forecast's own clock is the city's local time)
  function nextHours(d) {
    var h = d.hourly, out = []
    if (!h || !h.time) return out
    var cur = String(d.current.time).slice(0, 13)               // "YYYY-MM-DDTHH"
    var i = 0
    while (i < h.time.length && String(h.time[i]).slice(0, 13) <= cur) i++
    for (var k = i; k < h.time.length && out.length < 4; k++)
      out.push({ hour: String(h.time[k]).slice(11, 16), temp: h.temperature_2m[k], code: h.weather_code[k], day: h.is_day[k] === 1 })
    return out
  }
  // a colour for the weather, for the looks that tint themselves (full, round, tile)
  // the theme's accent with a hint of the weather's colour, so the looks
  // match the theme; "weatherColours" gives the plain weather colours
  function tone(code, day) {
    var hue = Qt.color(rawTone(code, day))
    if (opt("weatherColours", false) === true) return hue
    return Qt.tint(Color.accent, Qt.rgba(hue.r, hue.g, hue.b, 0.3))
  }
  function rawTone(code, day) {
    if (code === 0 || code === 1) return day ? "#f2c14e" : "#8fa8d8"
    if (code === 2 || code === 3) return "#9fb0c3"
    if (code === 45 || code === 48) return "#a3a3a3"
    if (code >= 51 && code <= 67 || code >= 80 && code <= 82) return "#6aa6e8"
    if (code >= 71 && code <= 77 || code >= 85 && code <= 86) return "#d6e8f7"
    if (code >= 95) return "#b48ead"
    return "#9fb0c3"
  }
  function refresh() {
    if (!place || fetch.running) return
    fetch.command = ["curl", "-fsS", "--max-time", "15",
      "https://api.open-meteo.com/v1/forecast?latitude=" + place.lat + "&longitude=" + place.lon +
      "&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m,relative_humidity_2m,is_day" +
      "&daily=temperature_2m_max,temperature_2m_min&hourly=temperature_2m,weather_code,is_day&forecast_days=2&timezone=auto"]
    fetch.running = true
  }
  Timer { interval: 15 * 60 * 1000; repeat: true; triggeredOnStart: true; running: wm.wanted; onTriggered: wm.refresh() }
  onPlaceChanged: refresh()

  // city search for the settings
  property var found: []
  property bool searching: false
  Process {
    id: geo
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        wm.searching = false
        try { var d = JSON.parse(text); wm.found = (d.results || []).map(function(r) {
          return { name: r.name, country: r.country || "", region: r.admin1 || "", lat: r.latitude, lon: r.longitude } }) }
        catch (e) { wm.found = [] }
      }
    }
  }
  function search(q) {
    q = String(q || "").trim()
    if (!q || geo.running) return
    searching = true
    geo.command = ["curl", "-fsS", "--max-time", "15", "-G", "https://geocoding-api.open-meteo.com/v1/search",
                   "--data-urlencode", "name=" + q, "--data-urlencode", "count=6", "--data-urlencode", "language=" + (ru ? "ru" : "en")]
    geo.running = true
  }
  function choose(p) { found = []; persist({ place: p }) }

  // WMO weather codes → glyph and words
  function glyph(code, day) {
    if (code === 0) return day ? "\u{f0599}" : "\u{f0594}"            // sunny / night
    if (code <= 2) return day ? "\u{f0595}" : "\u{f0f31}"             // partly cloudy
    if (code === 3) return "\u{f0590}"                                // cloudy
    if (code === 45 || code === 48) return "\u{f0591}"                // fog
    if (code >= 51 && code <= 67) return "\u{f0597}"                  // rain
    if (code >= 71 && code <= 77) return "\u{f0598}"                  // snow
    if (code >= 80 && code <= 82) return "\u{f0596}"                  // pouring
    if (code >= 85 && code <= 86) return "\u{f0f36}"                  // snowy heavy
    if (code >= 95) return "\u{f0593}"                                // lightning
    return "\u{f0590}"
  }
  function words(code) {
    var w = [[0, "Ясно", "Clear"], [1, "Почти ясно", "Mostly clear"], [2, "Переменная облачность", "Partly cloudy"],
             [3, "Пасмурно", "Overcast"], [45, "Туман", "Fog"], [48, "Изморозь", "Rime fog"], [51, "Морось", "Drizzle"],
             [61, "Дождь", "Rain"], [66, "Ледяной дождь", "Freezing rain"], [71, "Снег", "Snow"], [77, "Снежная крупа", "Snow grains"],
             [80, "Ливень", "Showers"], [85, "Снегопад", "Snow showers"], [95, "Гроза", "Thunderstorm"]]
    var best = w[0]
    for (var i = 0; i < w.length; i++) if (code >= w[i][0]) best = w[i]
    return ru ? best[1] : best[2]
  }
  function deg(v) { return v === null || v === undefined ? "—" : (Math.round(v) > 0 ? "+" : "") + Math.round(v) + "°" }

  // the temperature next to the clock in the collapsed notch
  ear: inNotch && now ? glyph(now.code, now.day) + " " + deg(now.temp) : ""

  // ------------------------------------------------------------ widget
  widgetTitle: t("Погода", "Weather")
  widgetIcon: "\u{f0595}"
  deskEnabled: opt("widget", false) === true
  function setDeskEnabled(on) { persist({ widget: on }) }
  deskDefault: ({ x: 0.82, y: 0.40 })
  widgetPage: Component { WeatherWidgetSettings { mod: wm } }
  deskWidget: Component { WeatherWidget { mod: wm } }
}
