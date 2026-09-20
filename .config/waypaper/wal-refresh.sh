#!/usr/bin/env bash
# Regenerate the pywal palette from the new wallpaper and refresh themed apps.
# Called by waypaper's post_command with the wallpaper path as $1.

[ -z "$1" ] && exit 1

# -n: don't set the wallpaper (waypaper already did), -q: quiet, -e: skip reloading env
wal -n -q -i "$1"

# keep hyprlock's blurred background in sync with the wallpaper
magick "$1" "$HOME/.cache/current_wallpaper.png" 2>/dev/null &

# waybar only watches its own style.css, not the @import'd wal file — poke it
pkill -SIGUSR2 waybar

# rebuild ghostty's palette from the new wal colours (script SIGUSR2s ghostty)
"$HOME/.config/waypaper/wal-ghostty.sh" 2>/dev/null &

# rofi needs an alpha-carrying colour var that pywal itself does not emit
"$HOME/.config/waypaper/wal-rofi.sh" 2>/dev/null &

# refresh swaync if running
swaync-client -rs >/dev/null 2>&1

# restart hyprlauncher daemon so its hyprtoolkit theme picks up the new palette
pkill -x hyprlauncher 2>/dev/null
(hyprlauncher -d --quiet >/dev/null 2>&1 &)

exit 0
