#!/usr/bin/env bash
# Rofi wifi picker — the click action for waybar's network module.
#
# Replaces `ghostty -e nmtui`. nmtui is a full-screen TUI for a job that is
# almost always "connect me to that network", which a one-shot rofi list does
# in a single keystroke. nm-connection-editor is still one entry away for the
# cases that genuinely need it (static IPs, VPNs, 802.1x).
#
# Parsing note: nmcli -t escapes colons inside values as '\:', and SSIDs here
# contain spaces and even trailing spaces, so the list is parsed in python
# rather than with cut/awk.

ACTION_RESCAN="󰑓  Rescan"
ACTION_TOGGLE_OFF="󰖪  Turn wifi off"
ACTION_TOGGLE_ON="󰖩  Turn wifi on"
ACTION_EDITOR="󰒓  Advanced (nm-connection-editor)"

radio=$(nmcli radio wifi 2>/dev/null)

build_list() {
/usr/bin/python3 - <<'PY'
import subprocess

def nm(args):
    try:
        return subprocess.run(["nmcli","-t"]+args, capture_output=True, text=True, timeout=10).stdout
    except Exception:
        return ""

def split_esc(line):
    """nmcli -t escapes ':' as '\\:' and '\\' as '\\\\'."""
    out, cur, esc = [], [], False
    for ch in line:
        if esc:
            cur.append(ch); esc = False
        elif ch == "\\":
            esc = True
        elif ch == ":":
            out.append("".join(cur)); cur = []
        else:
            cur.append(ch)
    out.append("".join(cur))
    return out

saved = set()
for ln in nm(["-f","NAME,TYPE","con","show"]).splitlines():
    p = split_esc(ln)
    if len(p) >= 2 and "wireless" in p[1]:
        saved.add(p[0])

ICONS = ["󰤯","󰤟","󰤢","󰤥","󰤨"]
seen = set()
for ln in nm(["-f","IN-USE,SSID,SECURITY,SIGNAL","dev","wifi","list"]).splitlines():
    p = split_esc(ln)
    if len(p) < 4:
        continue
    inuse, ssid, sec, sig = p[0], p[1], p[2], p[3]
    if not ssid or ssid in seen:
        continue
    seen.add(ssid)
    try:
        s = int(sig)
    except ValueError:
        s = 0
    icon = ICONS[min(s // 21, 4)]
    marks = []
    if inuse.strip() == "*": marks.append("connected")
    if ssid in saved:        marks.append("saved")
    if not sec:              marks.append("open")
    suffix = "  ·  " + ", ".join(marks) if marks else ""
    # tab-delimited: label \t ssid \t saved \t secured
    print(f"{icon}  {ssid}{suffix}\t{ssid}\t{int(ssid in saved)}\t{int(bool(sec))}")
PY
}

LIST=$(mktemp -t wifi-picker.XXXXXX)
trap 'rm -f "$LIST"' EXIT

{
  if [ "$radio" = "enabled" ]; then
      build_list
      printf '%s\t__RESCAN__\t0\t0\n' "$ACTION_RESCAN"
      printf '%s\t__TOGGLE__\t0\t0\n' "$ACTION_TOGGLE_OFF"
  else
      printf '%s\t__TOGGLE__\t0\t0\n' "$ACTION_TOGGLE_ON"
  fi
  printf '%s\t__EDITOR__\t0\t0\n' "$ACTION_EDITOR"
} > "$LIST"

choice=$(cut -f1 "$LIST" | rofi -dmenu -i -p "wifi" -lines 12 2>/dev/null)
[ -z "$choice" ] && exit 0

line=$(grep -m1 -F "$choice"$'\t' "$LIST")
# rofi can hand back text that matches no row (custom input, or a stale list
# if the scan changed under us). Without this guard the script fell through
# to `nmcli dev wifi connect ""`.
if [ -z "$line" ]; then
    notify-send -a "Wi-Fi" "No such network" "$choice" 2>/dev/null
    exit 1
fi
ssid=$(printf '%s' "$line" | cut -f2)
is_saved=$(printf '%s' "$line" | cut -f3)
is_secured=$(printf '%s' "$line" | cut -f4)
rm -f "$LIST"; trap - EXIT

notify() { notify-send -a "Wi-Fi" "$1" "$2" 2>/dev/null; }

case "$ssid" in
  __RESCAN__) nmcli dev wifi rescan 2>/dev/null; exec "$0" ;;
  __TOGGLE__)
      if [ "$radio" = "enabled" ]; then nmcli radio wifi off; notify "Wi-Fi off" ""
      else nmcli radio wifi on; notify "Wi-Fi on" ""; fi
      exit 0 ;;
  __EDITOR__) exec nm-connection-editor ;;
esac

# Saved network: bring the existing profile up. No password needed, and
# nothing sensitive ever reaches the process list.
if [ "$is_saved" = "1" ]; then
    if nmcli con up id "$ssid" >/dev/null 2>&1; then notify "Connected" "$ssid"
    else notify "Failed to connect" "$ssid"; fi
    exit 0
fi

if [ "$is_secured" = "1" ]; then
    pass=$(printf '' | rofi -dmenu -password -p "password for $ssid" -lines 0 2>/dev/null)
    [ -z "$pass" ] && exit 0
    ok=$(nmcli dev wifi connect "$ssid" password "$pass" 2>&1); rc=$?
    unset pass
else
    ok=$(nmcli dev wifi connect "$ssid" 2>&1); rc=$?
fi

if [ $rc -eq 0 ]; then notify "Connected" "$ssid"
else notify "Failed to connect" "$(printf '%s' "$ok" | tail -1)"; fi
