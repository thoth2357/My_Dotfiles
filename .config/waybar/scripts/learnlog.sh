#!/usr/bin/env bash
# Today's learning captures + untriaged inbox depth, for waybar. Hides at zero.
#
# Reads the Syncthing-backed pool at ~/ALIAS/learning, so the count includes
# anything captured on another device and synced here.

NL=$'\n'
POOL="$HOME/ALIAS/learning"
today=$(date +%F)
daily="$POOL/daily/$today.md"

n=0
[ -f "$daily" ] && n=$(grep -c '^- ' "$daily" 2>/dev/null)
[ -z "$n" ] && n=0

# Untriaged depth: everything still sitting in INBOX rather than in topics/.
inbox=0
[ -f "$POOL/INBOX.md" ] && inbox=$(grep -c '^- ' "$POOL/INBOX.md" 2>/dev/null)
[ -z "$inbox" ] && inbox=0

[ "$n" -eq 0 ] && [ "$inbox" -eq 0 ] && exit 0

conflicts=$(find "$POOL" -maxdepth 1 -name 'INBOX.sync-conflict-*.md' 2>/dev/null | wc -l)

if [ "$n" -gt 0 ]; then text="󰎚 $n"; else text="󰎚 ·"; fi

tip="Captured today: ${n}${NL}Inbox (untriaged): ${inbox}"
if [ -f "$daily" ] && [ "$n" -gt 0 ]; then
    last=$(grep '^- ' "$daily" | tail -1 | sed 's/^- //' | cut -c1-70)
    tip="${tip}${NL}Latest: ${last}"
fi
if [ "$conflicts" -gt 0 ]; then
    tip="${tip}${NL}${NL}⚠ ${conflicts} sync conflict(s) — run learn-merge.sh"
    class="conflict"
else
    class="learnlog"
fi
tip="${tip}${NL}${NL}SUPER+N to add · click to open inbox"

jq -nc --arg t "$text" --arg tip "$tip" --arg c "$class" '{text:$t, tooltip:$tip, class:$c}'
