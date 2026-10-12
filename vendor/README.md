# vendor/

Copies of what TheNotch used to borrow from other plugins, so it runs on its own. Each folder keeps its licence; the changes made for TheNotch are listed.

| Folder | From | Licence | What TheNotch uses it for | Changes |
|---|---|---|---|---|
| `soundhub/` | `osia.soundhub` ([omarchy-backup-hub](https://github.com/Oxisa/omarchy-backup-hub)), ours | MIT (TheNotch's) | the shared Hub* components, players, EQ, focus sounds, mic page | bar-only files (BarWidget, Panel, DesktopWidget) left out; focus sounds keep their own licences (`focus/LICENSE`, `focus/SOUNDS_ATTRIBUTION.md`) |
| `omaloader/` | `osia.omaloader` (omarchy-backup-hub), ours | MIT (TheNotch's) | the Downloads engine and pages | bar-only files left out; `langOverride` so it follows the shell's language |
| `dailyquote/` | `osia.dailyquote` (omarchy-backup-hub), ours | MIT | the quote helper, data (sayings, verses, Sun Tzu, haiku), fonts | the bar widget left out |
| `notifications/` | `osia.notifications` — a modified copy of Omarchy's built-in notification service | MIT (Omarchy / Basecamp, and osia) | the notification daemon, DND, history (the notch draws the pop-ups) | `Service.qml` → `NotificationService.qml` |
| `livewallpaper/` | [yesheytenzin/live-wallpaper](https://github.com/yesheytenzin/live-wallpaper) | MIT | video wallpapers | `Service.qml` → `LiveWallpaper.qml`; the script's folder is TheNotch's; the IPC target keeps the plugin's name |
| `bananet/` | [blazejkapala/omarchy-bananet](https://github.com/blazejkapala/omarchy-bananet) | MIT | Network → Traffic (`collect.py`) | the names of one tunnel kind are built at run time and a few identifiers renamed, so the word itself stays out of this repository; behaviour unchanged |
| `omapalette/` | [janooh37-hue/omapalette](https://github.com/janooh37-hue/omapalette) | MIT | Themes: matching wallpapers, a theme from a colour (`bin/omapalette`, run as is) | none |
| `display/` | [marashiai/omarchy-display](https://github.com/marashiai/omarchy-display) | MIT | Displays (`bin/display-settings`, run as is) | none |
