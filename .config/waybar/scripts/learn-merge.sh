#!/usr/bin/env bash
# Fold Syncthing conflict copies of INBOX.md back into the real one.
#
# Two devices appending at the same moment makes Syncthing write
# INBOX.sync-conflict-<date>-<device>.md instead of losing an entry. This
# recovers any bullet lines that aren't already in INBOX.md, then removes the
# conflict files. Safe to run repeatedly.

POOL="$HOME/ALIAS/learning"
inbox="$POOL/INBOX.md"
[ -f "$inbox" ] || { echo "no inbox at $inbox"; exit 1; }

shopt -s nullglob
conflicts=("$POOL"/INBOX.sync-conflict-*.md)
[ ${#conflicts[@]} -eq 0 ] && { echo "no conflict files"; exit 0; }

recovered=0
for c in "${conflicts[@]}"; do
    while IFS= read -r line; do
        case "$line" in
            '- '*) grep -Fqx -- "$line" "$inbox" || { printf '%s\n' "$line" >> "$inbox"; recovered=$((recovered+1)); } ;;
        esac
    done < "$c"
    rm -f "$c"
done
echo "recovered $recovered entr$([ "$recovered" -eq 1 ] && echo y || echo ies) from ${#conflicts[@]} conflict file(s)"
