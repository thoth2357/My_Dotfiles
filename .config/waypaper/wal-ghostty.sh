#!/usr/bin/env bash
# Render the current pywal palette into a ghostty-format colour file.
#
# pywal's raw output is tuned for accuracy to the wallpaper, not for reading
# code at 12pt — colours regularly come out muddy or near-black. This pastelises
# palette slots 1-6 (saturation and lightness pinned into a soft band) so the
# terminal keeps following the wallpaper while staying legible and soft-edged.
#
# Output: ~/.cache/wal/colors-ghostty.conf, included by ~/.config/ghostty/config

set -e
OUT="$HOME/.cache/wal/colors-ghostty.conf"
[ -f "$HOME/.cache/wal/colors.json" ] || exit 0

python3 - "$OUT" <<'PY'
import json, sys, colorsys, os

out = sys.argv[1]
wal = json.load(open(os.path.expanduser("~/.cache/wal/colors.json")))

def hex2rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i+2], 16) / 255 for i in (0, 2, 4))

def rgb2hex(r, g, b):
    return "#%02X%02X%02X" % tuple(max(0, min(255, round(c * 255))) for c in (r, g, b))

def adjust(h, s_lo=0.45, s_hi=0.85, l_lo=0.62, l_hi=0.80):
    """Pin a colour's saturation/lightness into a soft pastel band, keeping hue."""
    r, g, b = hex2rgb(h)
    hh, ll, ss = colorsys.rgb_to_hls(r, g, b)
    ss = min(max(ss, s_lo), s_hi)
    ll = min(max(ll, l_lo), l_hi)
    return rgb2hex(*colorsys.hls_to_rgb(hh, ll, ss))

def shade(h, factor):
    """Scale lightness by factor (>1 lighter, <1 darker), hue/sat untouched."""
    r, g, b = hex2rgb(h)
    hh, ll, ss = colorsys.rgb_to_hls(r, g, b)
    ll = min(max(ll * factor, 0.0), 1.0)
    return rgb2hex(*colorsys.hls_to_rgb(hh, ll, ss))

bg = wal["special"]["background"]
c  = wal["colors"]

# Normal 1-6 pastelised; brights 9-14 are the same hues nudged lighter.
normal  = [adjust(c[f"color{i}"]) for i in range(1, 7)]
bright  = [shade(x, 1.12) for x in normal]

# Lightness band deliberately sits BELOW pywal's own foreground lightness
# (~0.77 for a typical wallpaper) rather than forcing it up. The old band
# (0.86-0.93) pushed every foreground to near-white, which is what made the
# terminal glare: white-on-near-black haloes, and it flattened the palette.
fg      = adjust(wal["special"]["foreground"], s_lo=0.10, s_hi=0.30, l_lo=0.72, l_hi=0.82)
black   = shade(bg, 1.9)          # visible-but-dim slot 0
grey    = adjust(bg, s_lo=0.08, s_hi=0.22, l_lo=0.42, l_hi=0.52)  # slot 8
cursor  = normal[4] if len(normal) > 4 else fg

lines = [
    "# Auto-generated from pywal by ~/.config/waypaper/wal-ghostty.sh",
    "# Do not edit: rewritten on every wallpaper change.",
    "",
    f"background = {bg}",
    f"foreground = {fg}",
    f"cursor-color = {cursor}",
    f"selection-background = {shade(normal[3], 0.45)}",
    f"selection-foreground = {fg}",
    "",
    f"palette = 0={black}",
]
for i, col in enumerate(normal, start=1):
    lines.append(f"palette = {i}={col}")
lines.append(f"palette = 7={fg}")
lines.append(f"palette = 8={grey}")
for i, col in enumerate(bright, start=9):
    lines.append(f"palette = {i}={col}")
# slot 15 (bright white) tracks the foreground instead of being pinned to
# #FFFFFF — nothing in the palette should be brighter than the text tier.
lines.append(f"palette = 15={shade(fg, 1.08)}")

open(out, "w").write("\n".join(lines) + "\n")
PY

# ghostty reloads its config in place on SIGUSR2
pkill -SIGUSR2 -x ghostty 2>/dev/null || true
exit 0
