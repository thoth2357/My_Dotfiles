#!/usr/bin/env bash
# Today's coding time from WakaTime, for waybar.
#
# WakaTime is already collecting on this machine and had no surface anywhere.
# Making practice time visible is self-monitoring, which is the point.
#
# Degrades to a neutral dash on failure rather than an error or a stale
# number: the wakatime logs show recurring upload failures from IPv6/DNS
# flakiness, and a confidently-wrong figure is worse than an honest blank.

NL=$'\n'
CLI="$HOME/.wakatime/wakatime-cli"
GOAL_MINUTES=240        # 4h — edit to taste

[ -x "$CLI" ] && out=$(timeout 12 "$CLI" --today 2>/dev/null) || out=""

# "2 hrs 36 mins" / "45 mins" / "1 hr" — pull the numbers out
if [ -z "$out" ]; then
    jq -nc '{text:"󰔟 —", tooltip:"WakaTime: unreachable\nToday'"'"'s total unavailable", class:"stale"}'
    exit 0
fi

hrs=$(printf '%s' "$out" | grep -oE '[0-9]+ hr'  | grep -oE '[0-9]+' | head -1)
mins=$(printf '%s' "$out" | grep -oE '[0-9]+ min' | grep -oE '[0-9]+' | head -1)
hrs=${hrs:-0}; mins=${mins:-0}
total=$(( hrs * 60 + mins ))

if [ "$total" -eq 0 ]; then
    text="󰔟 0m"
elif [ "$hrs" -eq 0 ]; then
    text="󰔟 ${mins}m"
else
    text="󰔟 ${hrs}h${mins}m"
fi

pct=$(( total * 100 / GOAL_MINUTES ))
if   [ "$pct" -ge 100 ]; then class="goal"
elif [ "$pct" -ge 50 ];  then class="mid"
else                          class="low"
fi

goal_h=$(( GOAL_MINUTES / 60 ))
tip="Coding today: ${out}${NL}Goal: ${goal_h}h (${pct}%)${NL}${NL}Click for the WakaTime dashboard"

jq -nc --arg t "$text" --arg tip "$tip" --arg c "$class" \
    '{text:$t, tooltip:$tip, class:$c}'
