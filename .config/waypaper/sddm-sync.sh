#!/usr/bin/env bash
# Sync the SDDM (Garuda login) look with the current rice. Run with sudo:
#   sudo ~/.config/waypaper/sddm-sync.sh
# Installs: login avatar, current wallpaper as login background, pywal accent color.

set -e
[ "$EUID" -eq 0 ] || { echo "run me with sudo"; exit 1; }

USER_HOME=/home/oluwaseyi
# Read the ACTIVE theme from sddm.conf instead of hardcoding one. This was
# pinned to Sweet6, which is NOT the theme in use (Current=pixel-night-city),
# so every background/accent sync was being written to a theme nothing loads.
THEME_NAME=$(grep -oP '^Current=\K.*' /etc/sddm.conf 2>/dev/null | tr -d '[:space:]')
[ -n "$THEME_NAME" ] || THEME_NAME=$(grep -rhoP '^Current=\K.*' /etc/sddm.conf.d/ 2>/dev/null | tail -1 | tr -d '[:space:]')
THEME=/usr/share/sddm/themes/$THEME_NAME
[ -d "$THEME" ] || { echo "active theme '$THEME_NAME' not found under /usr/share/sddm/themes"; exit 1; }
echo "active theme: $THEME_NAME"

# 1. Avatar (home is 700, so it must live in the system faces dir)
install -m 644 "$USER_HOME/.face.icon" /usr/share/sddm/faces/oluwaseyi.face.icon
echo "avatar installed"

# 2. Login background = current wallpaper.
#    Read the target from the theme's own theme.conf rather than assuming
#    assets/bg.jpg. pixel-night-city uses a VIDEO background, and the old
#    hardcoded path made `magick` fail into a directory that does not exist —
#    which, under `set -e`, aborted the script before step 3 ever ran.
BG_TYPE=$(grep -oP '^type=\K.*' "$THEME/theme.conf" 2>/dev/null | tr -d '[:space:]')
BG_FILE=$(grep -oP '^background=\K.*' "$THEME/theme.conf" 2>/dev/null | tr -d '[:space:]')

if [ "$BG_TYPE" = "video" ]; then
    echo "background: theme uses a video ($BG_FILE) — leaving it alone"
elif [ -n "$BG_FILE" ]; then
    WALL=$(grep -oP '^wallpaper = \K.*' "$USER_HOME/.config/waypaper/config.ini" | sed "s|~|$USER_HOME|")
    if [ -f "$WALL" ] && [ -d "$(dirname "$THEME/$BG_FILE")" ]; then
        cp "$THEME/$BG_FILE" "$THEME/$BG_FILE.orig" 2>/dev/null || true
        magick "$WALL" -resize 1920x1080^ -gravity center -extent 1920x1080 "$THEME/$BG_FILE"
        echo "background set to $(basename "$WALL")"
    else
        echo "background: skipped (wallpaper or target dir missing)"
    fi
else
    echo "background: theme declares none — skipped"
fi

# 3. Accent color from pywal
ACCENT=$(grep -m1 -oP 'color9 \K#[0-9A-Fa-f]{6}' "$USER_HOME/.cache/wal/colors-waybar.css" || true)
if [ -n "$ACCENT" ]; then
    sed -i "s/^selected_color=.*/selected_color=$ACCENT/" "$THEME/theme.conf"
    echo "accent set to $ACCENT"
fi
