#!/usr/bin/env bash
# One-line learning capture, bound to SUPER+N.
#
# Writes into the Syncthing-backed pool at ~/ALIAS/learning so captures from
# this machine and from any other synced device land in the same place.
# Every entry carries the host, so a pooled inbox still says where it came from.

POOL="$HOME/ALIAS/learning"
HOST=$(hostnamectl --static 2>/dev/null || hostname)
today=$(date +%F)

mkdir -p "$POOL/daily" "$POOL/topics"

entry=$(rofi -dmenu -p "learned" -lines 0 -width 40 </dev/null 2>/dev/null)
[ -z "$entry" ] && exit 0

line=$(printf -- '- `%s %s` %s' "$(date '+%H:%M')" "$HOST" "$entry")

# INBOX is the triage surface; daily/ is the archive. Both get the entry.
[ -f "$POOL/INBOX.md" ] || printf '# Inbox\n\nUntriaged captures. Move things into `topics/` as you process them.\n\n' > "$POOL/INBOX.md"
printf '%s\n' "$line" >> "$POOL/INBOX.md"

daily="$POOL/daily/$today.md"
[ -f "$daily" ] || printf '# %s\n\n' "$(date '+%A, %d %B %Y')" > "$daily"
printf '%s\n' "$line" >> "$daily"

pkill -SIGRTMIN+7 waybar 2>/dev/null
notify-send -a "Learning" "Captured to pool" "$entry" 2>/dev/null
