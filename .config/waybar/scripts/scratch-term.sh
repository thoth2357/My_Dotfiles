#!/usr/bin/env bash
# Drop-down scratchpad terminal, bound to SUPER+grave.
#
# First press spawns a ghostty tagged with a dedicated app-id; a window rule
# in hyprland.lua routes anything with that class into special:magic, so it
# lands in the scratchpad rather than the tiling layout. Later presses just
# toggle the scratchpad's visibility, so the shell and its scrollback persist.

CLASS="com.scratch.term"

exists=$(hyprctl clients -j 2>/dev/null | /usr/bin/python3 -c '
import sys, json
try: cs = json.load(sys.stdin)
except Exception: cs = []
print(sum(1 for c in cs if c.get("class") == "'"$CLASS"'"))
')

if [ "${exists:-0}" -gt 0 ]; then
    hyprctl dispatch 'hl.dsp.workspace.toggle_special("magic")' >/dev/null 2>&1
else
    # The window rule sends it to special:magic; show the scratchpad so it's
    # visible the moment it maps.
    ghostty --class="$CLASS" >/dev/null 2>&1 &
    sleep 0.4
    hyprctl dispatch 'hl.dsp.workspace.toggle_special("magic")' >/dev/null 2>&1
fi

# refresh the waybar counter immediately rather than waiting for its poll
pkill -SIGRTMIN+5 waybar 2>/dev/null || true
