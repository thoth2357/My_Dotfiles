#!/usr/bin/env bash
# Sync the SDDM (Garuda login) look with the current rice. Run with sudo:
#   sudo ~/.config/waypaper/sddm-sync.sh
# Installs: login avatar, current wallpaper as login background, pywal accent color.

set -e
[ "$EUID" -eq 0 ] || { echo "run me with sudo"; exit 1; }

USER_HOME=/home/oluwaseyi
THEME=/usr/share/sddm/themes/Sweet6

# 1. Avatar (home is 700, so it must live in the system faces dir)
install -m 644 "$USER_HOME/.face.icon" /usr/share/sddm/faces/oluwaseyi.face.icon
echo "avatar installed"

# 2. Login background = current wallpaper
WALL=$(grep -oP '^wallpaper = \K.*' "$USER_HOME/.config/waypaper/config.ini" | sed "s|~|$USER_HOME|")
if [ -f "$WALL" ]; then
    cp "$THEME/assets/bg.jpg" "$THEME/assets/bg.jpg.orig" 2>/dev/null || true
    magick "$WALL" -resize 1920x1080^ -gravity center -extent 1920x1080 "$THEME/assets/bg.jpg"
    echo "background set to $(basename "$WALL")"
fi

# 3. Accent color from pywal
ACCENT=$(grep -m1 -oP 'color9 \K#[0-9A-Fa-f]{6}' "$USER_HOME/.cache/wal/colors-waybar.css" || true)
if [ -n "$ACCENT" ]; then
    sed -i "s/^selected_color=.*/selected_color=$ACCENT/" "$THEME/theme.conf"
    echo "accent set to $ACCENT"
fi
