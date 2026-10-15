#!/usr/bin/env bash
# TheNotch installer.
#
#   ./install.sh               install (or link this folder) and set Omarchy up for it
#   ./install.sh --check       only report what's there and what's missing
#   ./install.sh --uninstall   undo what TheNotch changed outside its folder
#
# TheNotch carries everything it needs from other plugins (vendor/). What it
# cannot carry are system programs and a few settings outside its folder —
# all of them are listed below, so nothing is a surprise.
set -uo pipefail

ID="osia.thenotch"
REPO="https://github.com/Oxisa/TheNotch.git"
HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
PLUGINS="$HOME/.config/omarchy/plugins"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
miss() { printf '  \033[33m·\033[0m %s\n' "$*"; }

# ---------------------------------------------------------------- programs
# program | package (pacman, or aur:) | what needs it
OPTIONAL=(
  "fastfetch|fastfetch|Settings → System → This computer"
  "ddcutil|ddcutil|monitor brightness (DDC)"
  "ffmpeg|ffmpeg|video wallpapers, video previews"
  "mpv|mpv|Sound → Ambient, camera preview"
  "yt-dlp|yt-dlp|YouTube links in Ambient, Downloads"
  "socat|socat|Ambient volume while playing"
  "cava|cava|the music spectrum"
  "aether|aether|Themes: matching wallpapers, a theme from a colour"
  "avahi-browse|avahi|printers on the network"
  "solaar|solaar|Logitech mouse"
  "kcd|aur:kcd-bin|Phone (KDE Connect)"
  "syncthing|syncthing|Syncthing"
  "jq|jq|several backends"
  "curl|curl|weather, quotes, calendars"
)

check_programs() {
  bold "Programs (optional — each only for its feature)"
  MISSING_PAC=(); MISSING_AUR=()
  for row in "${OPTIONAL[@]}"; do
    IFS='|' read -r bin pkg what <<<"$row"
    if command -v "$bin" >/dev/null 2>&1; then ok "$bin — $what"
    else
      miss "$bin — $what (not installed)"
      if [[ $pkg == aur:* ]]; then MISSING_AUR+=("${pkg#aur:}"); else MISSING_PAC+=("$pkg"); fi
    fi
  done
}

offer_programs() {
  (( ${#MISSING_PAC[@]} + ${#MISSING_AUR[@]} )) || return 0
  echo
  read -r -p "Install the missing ones now? [y/N] " a
  [[ $a == [yY]* ]] || return 0
  (( ${#MISSING_PAC[@]} )) && sudo pacman -S --needed "${MISSING_PAC[@]}"
  if (( ${#MISSING_AUR[@]} )); then
    if command -v yay >/dev/null; then yay -S --needed "${MISSING_AUR[@]}"
    else miss "AUR packages need yay: ${MISSING_AUR[*]}"; fi
  fi
}

# --------------------------------------------------------- what it changes
explain() {
  bold "What TheNotch changes outside its folder"
  cat <<'EOF'
  Omarchy
    · hides the Omarchy bar while it runs (omarchy toggle bar)
    · receives notifications itself — Omarchy's own service (omarchy.notifications)
      must stay off, or two daemons would fight over notifications
    · Style → Background in the Omarchy menu opens the picker with video support
      (~/.config/omarchy/extensions/omarchy-menu.jsonc, the "style.background" entry)
  Hyprland — blocks between "-- BEGIN thenotch-…" / "-- END thenotch-…", only when you
  change those settings
    · ~/.config/hypr/looknfeel.lua   window look, workspace tiling modes, cursor
    · ~/.config/hypr/bindings.lua    Super+` overview, Super+Shift+drag snap zones
    · ~/.config/hypr/input.lua       pointer and keyboard settings
    · ~/.config/hypr/monitors.lua    monitor layout (the display backend's own block)
  Other files
    · ~/.config/thenotch/            settings, calendars, your events
    · ~/.local/share/thenotch/       notes, shelf, the Sony headphones helper
    · ~/.local/state/thenotch/       the privacy log
    · ~/.config/fontconfig/conf.d/60-thenotch.conf and ~/.local/share/fonts/thenotch/
      (only if you pick the Goetia preset or add a font)
    · ~/.config/omarchy/hooks/post-boot.d/thenotch-cursor (only for a custom cursor),
      theme-set.d/thenotch-cursor-accent and ~/.local/share/icons/TheNotch-Accent
      (only for the cursor in the theme's colour)
    · ~/.config/omarchy/backgrounds/thenotch-videos/ (links to video wallpapers you set)
    · ~/Documents/Notes (or Заметки) — a Markdown copy of each note (switch off in Notes)
  Optional plugins it can install for you from Settings
    · Lock Designs (lock screen)
EOF
}

# ------------------------------------------------------------------ install
install() {
  bold "TheNotch"
  command -v omarchy >/dev/null || { echo "Omarchy is needed."; exit 1; }
  mkdir -p "$PLUGINS"
  if [[ -e $PLUGINS/$ID ]]; then ok "already installed ($PLUGINS/$ID)"
  elif [[ -f $HERE/manifest.json ]] && grep -q "\"$ID\"" "$HERE/manifest.json"; then
    ln -s "$HERE" "$PLUGINS/$ID" && ok "linked this folder"
  else
    omarchy plugin add "$REPO" --yes >/dev/null && ok "added from $REPO"
  fi
  omarchy plugin enable "$ID" >/dev/null 2>&1 && ok "enabled"
  # one notification daemon: TheNotch's
  omarchy plugin disable omarchy.notifications >/dev/null 2>&1 && ok "Omarchy's notification service off (TheNotch takes over)"
  echo
  check_programs
  offer_programs
  echo
  explain
  echo
  omarchy restart shell >/dev/null 2>&1 && ok "shell restarted"
}

# ---------------------------------------------------------------- uninstall
uninstall() {
  bold "Removing TheNotch's changes"
  omarchy plugin disable "$ID" >/dev/null 2>&1 && ok "TheNotch off"
  omarchy plugin enable omarchy.notifications >/dev/null 2>&1 && ok "Omarchy's notification service back on"
  omarchy toggle bar off >/dev/null 2>&1 || true
  # the marked blocks in the Hyprland files
  for f in looknfeel bindings input; do
    p="$HOME/.config/hypr/$f.lua"
    [[ -f $p ]] || continue
    python3 -I - "$p" <<'PY'
import re, sys
p = sys.argv[1]; s = open(p).read()
t = re.sub(r"\n?-- BEGIN thenotch-[a-z-]+.*?-- END thenotch-[a-z-]+\n?", "\n", s, flags=re.S)
if t != s:
    open(p, "w").write(t.rstrip("\n") + "\n"); print("  ✓ cleaned " + p)
PY
  done
  rm -f "$HOME/.config/omarchy/hooks/post-boot.d/thenotch-cursor" "$HOME/.config/omarchy/hooks/theme-set.d/thenotch-cursor-accent" \
        "$HOME/.config/fontconfig/conf.d/60-thenotch.conf"
  [[ -x $PLUGINS/$ID/vendor/livewallpaper/live-wallpaper.sh ]] && "$PLUGINS/$ID/vendor/livewallpaper/live-wallpaper.sh" --unwire-menu >/dev/null 2>&1
  ok "hooks, font alias and the menu entry removed"
  echo "  Your data stays: ~/.config/thenotch, ~/.local/share/thenotch, ~/.local/state/thenotch."
  echo "  To remove the plugin itself: omarchy plugin remove $ID"
  omarchy restart shell >/dev/null 2>&1 || true
}

case "${1:-}" in
  --check) check_programs; echo; explain ;;
  --uninstall) uninstall ;;
  *) install ;;
esac
