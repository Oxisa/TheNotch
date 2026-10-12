.pragma library
// The settings window's sections, in order (like Windows Settings). Modules
// put their settings into one of these with `settingsSection`; a section
// with nothing in it is not shown.
var SECTIONS = [
  { id: "system",    icon: "\u{f0aab}", ru: "Система",               en: "System" },
  { id: "network",   icon: "\u{f059f}", ru: "Сеть и интернет",       en: "Network & internet" },
  { id: "bluetooth", icon: "\u{f00af}", ru: "Bluetooth и устройства", en: "Bluetooth & devices" },
  { id: "displays",  icon: "\u{f037a}", ru: "Дисплеи",               en: "Displays" },
  { id: "sound",     icon: "\u{f057e}", ru: "Звук",                  en: "Sound" },
  { id: "input",     icon: "\u{f030c}", ru: "Ввод",                  en: "Input" },
  { id: "personal",  icon: "\u{f03d8}", ru: "Персонализация",        en: "Personalisation" },
  { id: "workspaces", icon: "\u{f0570}", ru: "Рабочие столы",        en: "Workspaces" },
  { id: "privacy",   icon: "\u{f0565}", ru: "Конфиденциальность",    en: "Privacy" },
  { id: "apps",      icon: "\u{f003b}", ru: "Приложения",            en: "Apps" },
  { id: "modules",   icon: "\u{f0a1a}", ru: "Модули",                en: "Modules" },
  { id: "plugins",   icon: "\u{f0431}", ru: "Плагины Omarchy",       en: "Omarchy plugins" },
]
