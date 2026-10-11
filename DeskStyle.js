.pragma library
// The look every desktop widget shares, set per widget in the layout
// editor ("Style"): background colour and opacity, corner radius, border,
// text and accent colours. A widget reads it through these helpers with its
// own defaults; the window around it adds opacity, a shadow and scale.
//   { bg: "theme"|"accent"|"#rrggbb", bgOpacity, radius, border: bool,
//     text: "theme"|"#rrggbb", accent: "theme"|"#rrggbb", opacity, shadow: bool }

function pick(style, key, fallback) {
  return style && style[key] !== undefined && style[key] !== null && style[key] !== "" ? style[key] : fallback
}
function color(spec, theme, accent) {
  if (!spec || spec === "theme") return theme
  if (spec === "accent") return accent
  return Qt.color(spec)
}
// the card's fill: theme background (or the chosen colour) at the chosen opacity
function bg(style, themeBg, accent, defaultOpacity) {
  var c = color(pick(style, "bg", "theme"), themeBg, accent)
  return Qt.rgba(c.r, c.g, c.b, Number(pick(style, "bgOpacity", defaultOpacity)))
}
function fg(style, themeFg) { return color(pick(style, "text", "theme"), themeFg, themeFg) }
function accent(style, themeAccent) { return color(pick(style, "accent", "theme"), themeAccent, themeAccent) }
function radius(style, fallback) { return Number(pick(style, "radius", fallback)) }
function border(style, themeFg) {
  var on = pick(style, "border", true)
  return on ? Qt.rgba(themeFg.r, themeFg.g, themeFg.b, 0.10) : "transparent"
}
// one corner's radius: corners = { tl, tr, bl, br } when set one by one,
// otherwise the common radius
function corner(style, key, fallback) {
  var c = style && style.corners
  if (c && c[key] !== undefined && c[key] !== null) return Number(c[key])
  return radius(style, fallback)
}
