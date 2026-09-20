#!/usr/bin/env bash
# Screen recording toggle (wl-screenrec, VAAPI hardware encode).
#   record.sh          → select a region with slurp, start recording
#   record.sh output   → record the focused monitor
#   run again (either) → stop, notify, copy file path to clipboard
# Bound to SUPER+SHIFT+R (region) and SUPER+CTRL+R (monitor).

DIR="$HOME/Videos/recordings"
mkdir -p "$DIR"

# already recording → stop and report
if pgrep -x wl-screenrec >/dev/null; then
    pkill -INT -x wl-screenrec
    sleep 0.5   # let the container finalize
    f=$(ls -t "$DIR"/*.mp4 2>/dev/null | head -1)
    printf '%s' "$f" | wl-copy
    notify-send -a screenrec "󰻃 Recording stopped" "${f##*/}\npath copied to clipboard"
    exit 0
fi

command -v wl-screenrec >/dev/null || {
    notify-send -u critical -a screenrec "wl-screenrec not installed" "sudo pacman -S wl-screenrec"
    exit 1
}

f="$DIR/rec-$(date +%Y%m%d-%H%M%S).mp4"

if [ "$1" = "output" ]; then
    mon=$(hyprctl monitors -j | python3 -c "import json,sys; print([m['name'] for m in json.load(sys.stdin) if m['focused']][0])")
    wl-screenrec -o "$mon" -f "$f" &
    notify-send -a screenrec "󰑊 Recording $mon" "same key to stop"
else
    geom=$(slurp -d) || exit 0   # Esc cancels
    wl-screenrec -g "$geom" -f "$f" &
    notify-send -a screenrec "󰑊 Recording region" "same key to stop"
fi
