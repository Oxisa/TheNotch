.pragma library
// TheNotch core strings (modules carry their own).
var STRINGS = {
  en: {
    volume: "Volume", muted: "Muted", settings: "TheNotch",
    edge: "Position", "edge.top": "Top", "edge.bottom": "Bottom", "edge.left": "Left", "edge.right": "Right",
    hideBar: "Hide the Omarchy bar", hideBarHint: "While TheNotch is on, the bar is hidden (omarchy toggle bar)",
    language: "Language", look: "Look", "look.theme": "Theme", "look.black": "Black",
    events: "Live events", eventsVolume: "Volume changes", eventsTrack: "Track changes"
  },
  ru: {
    volume: "Громкость", muted: "Звук выключен", settings: "TheNotch",
    edge: "Положение", "edge.top": "Сверху", "edge.bottom": "Снизу", "edge.left": "Слева", "edge.right": "Справа",
    hideBar: "Скрывать панель Omarchy", hideBarHint: "Пока TheNotch включён, панель спрятана (omarchy toggle bar)",
    language: "Язык", look: "Цвет", "look.theme": "Как тема", "look.black": "Чёрный",
    events: "Живые события", eventsVolume: "Изменение громкости", eventsTrack: "Смена трека"
  }
}
function t(lang, key, args) {
  var s = (STRINGS[lang] || STRINGS.en)[key]
  if (s === undefined) s = STRINGS.en[key] !== undefined ? STRINGS.en[key] : key
  if (args !== undefined) s = String(s).replace("{0}", args)
  return s
}
