# TheNotch modules

A dashboard is a folder with a `Module.qml` whose root is `NotchModule`
(`import "../.."`), plus a line in `index.js`. The core sets `notch`,
`moduleId` and `order`; the module fills in what it has:

| Property | Meaning |
|---|---|
| `title`, `icon` | Name and Nerd Font glyph on the icon row |
| `page`, `pageWidth` | The dashboard (a `Component`) and its width in `Style.space` units |
| `live`, `livePriority` | Something is going on; the collapsed notch shows this module's ears |
| `liveLeft`, `liveRight` | The two ears (Components) while live |
| `peek`, `peekWidth` | Card shown on hover while live |
| `settingsPage` | Its section in the settings window (the gear); keep settings out of `page` |
| `inRail` | `false` for a settings-only module (no icon on the row) |
| `sectionOrder` | Place in the settings sidebar |
| `core`, `description` | Core sections can't be switched off; the description shows under Settings → Modules |
| `active` | (read-only) the module's on/off from Settings → Modules — skip live views and events when off |
| `widgetPage`, `widgetTitle`, `widgetIcon` | Its desktop widget's card under Settings → Widgets |

Settings: `notch.moduleOpt(id, key, default)` / `notch.modulePersist(id, {…})`
(stored under `modules.<id>` in `~/.config/thenotch/settings.json`).
Events: `notch.flash({ key, icon | art, title, message | progress, ms })`; an
event with the same `key` replaces the one on screen.
