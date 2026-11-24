#!/bin/sh

sketchybar --set $NAME label="$(df -H | grep -E '^(/dev/disk1s5s1).' | awk '{ printf ("%s\n", $5) }')"
