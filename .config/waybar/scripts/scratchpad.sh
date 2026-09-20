#!/usr/bin/env bash
# Windows parked in a Hyprland special workspace (scratchpad), for waybar.
#
# Exists because scratchpad windows are hidden but still running, and nothing
# otherwise tells you something is in there — easy to leave a process parked
# for days. Hides at zero, so it only appears when there IS something to know.

NL=$'\n'

json=$(hyprctl clients -j 2>/dev/null)
[ -z "$json" ] && exit 0

printf '%s' "$json" | /usr/bin/python3 -c '
import sys, json

try:
    clients = json.load(sys.stdin)
except Exception:
    sys.exit(0)

items = [c for c in clients
         if (c.get("workspace") or {}).get("name", "").startswith("special:")]
if not items:
    sys.exit(0)

lines = []
for c in items:
    ws = c["workspace"]["name"].split(":", 1)[-1]
    title = (c.get("title") or "").strip()[:48]
    cls = c.get("class") or "?"
    lines.append(f"  [{ws}] {cls}" + (f" — {title}" if title else ""))

tip = f"Scratchpad: {len(items)} window" + ("s" if len(items) != 1 else "")
tip += "\n" + "\n".join(lines)
tip += "\n\nSUPER+S to show/hide · click to toggle"

print(json.dumps({"text": f"󰘸 {len(items)}", "tooltip": tip, "class": "scratchpad"}))
'
