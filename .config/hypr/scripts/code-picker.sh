#!/usr/bin/env bash
# VS Code project picker for SUPER+C.
#
# Opens a rofi list and launches `code` straight into the chosen project, so
# there's no bare window + File>Open Folder dance.
#
# Deliberately NOT the Project Manager extension's own picker: that requires a
# VS Code window to already exist (its commands aren't reachable from the CLI),
# and its store is empty here anyway. This reads what VS Code itself knows.
#
# Sources, in priority order:
#   1. VS Code recents  (profileAssociations.workspaces in storage.json)
#      Local folders only — `code` 1.136.1 exposes neither --folder-uri nor
#      --remote (checked the full --help), so vscode-remote:// entries are
#      skipped rather than shipped as a button that silently does nothing.
#   2. Project Manager  (projects.json, if it ever gets populated)
#   3. A shallow scan of the usual project roots, so new work shows up
#      without having been opened once first.

LIST=$(mktemp -t code-picker.XXXXXX)
trap 'rm -f "$LIST"' EXIT

/usr/bin/python3 - "$@" <<'PY' > "$LIST"
import json, os, urllib.parse, glob

home = os.path.expanduser("~")
seen, items = set(), []          # items: (label, target, is_uri)

def add(target, is_uri=False):
    if target in seen:
        return
    seen.add(target)
    if is_uri:
        dec = urllib.parse.unquote(target)
        host = dec.split("+", 1)[-1].split("/")[0] if "+" in dec else "remote"
        label = f"󰢹 {os.path.basename(dec.rstrip('/'))}  ({host})"
    else:
        if not os.path.isdir(target):
            return                                   # drop stale recents
        if os.path.realpath(target) == os.path.realpath(home):
            return                                   # $HOME is not a project
        try:
            if not any(not e.name.startswith(".") for e in os.scandir(target)):
                return                               # skip empty dirs
        except OSError:
            return
        short = target.replace(home, "~")
        label = f"󰉋 {os.path.basename(target)}  {os.path.dirname(short)}"
    items.append((label, target, is_uri))

# 1. VS Code recents
sj = os.path.join(home, ".config/Code/User/globalStorage/storage.json")
try:
    ws = json.load(open(sj)).get("profileAssociations", {}).get("workspaces", {})
    for uri in ws:
        if uri.startswith("file://"):
            add(urllib.parse.unquote(uri[7:]))
        # vscode-remote:// deliberately skipped — see header
except Exception:
    pass

# 2. Project Manager, if populated
pj = os.path.join(home, ".config/Code/User/globalStorage/alefragnani.project-manager/projects.json")
try:
    for p in json.load(open(pj)):
        if p.get("rootPath"):
            add(os.path.expanduser(p["rootPath"].replace("$home", home)))
except Exception:
    pass

# 3. shallow scan of project roots
for root in ("CodeHouse", "work", "Projects"):
    base = os.path.join(home, root)
    if not os.path.isdir(base):
        continue
    add(base)
    for d in sorted(glob.glob(os.path.join(base, "*"))) + sorted(glob.glob(os.path.join(base, "*", "*"))):
        if os.path.isdir(d) and not os.path.basename(d).startswith((".", "__")):
            add(d)

# Actions first, so a project that isn't on disk yet is always reachable.
print("󰝒 New project…\t__NEW__\t0")
print("󰉗 Browse…\t__BROWSE__\t0")
for label, target, is_uri in items:
    print(f"{label}\t{target}\t{int(is_uri)}")
PY

[ -s "$LIST" ] || { notify-send -a "Code" "No projects found" 2>/dev/null; exit 0; }

choice=$(cut -f1 "$LIST" | rofi -dmenu -i -p "project" -lines 12 2>/dev/null)
[ -z "$choice" ] && exit 0

line=$(grep -m1 -F "$choice"$'\t' "$LIST")
target=$(printf '%s' "$line" | cut -f2)
is_uri=$(printf '%s' "$line" | cut -f3)

# Everything needed is now in variables. Drop the list file explicitly: this
# script ends in `exec`, which replaces the process, so the EXIT trap would
# never run and each invocation would leak a file into /tmp. The trap stays
# as a safety net for the early-exit paths above.
rm -f "$LIST"
trap - EXIT

case "$target" in
  __NEW__)
    # Path is taken relative to $HOME unless it starts with / or ~.
    # Prefilled with CodeHouse/ since that's where active work lives.
    name=$(printf '' | rofi -dmenu -p "new project" -filter "CodeHouse/" -lines 0 -width 40 2>/dev/null)
    [ -z "$name" ] && exit 0
    case "$name" in
      /*)  target="$name" ;;
      "~"*) target="${name/#\~/$HOME}" ;;
      *)   target="$HOME/$name" ;;
    esac
    if [ -e "$target" ] && [ ! -d "$target" ]; then
        notify-send -a "Code" "Not a directory" "$target" 2>/dev/null; exit 1
    fi
    if ! mkdir -p "$target" 2>/dev/null; then
        notify-send -a "Code" "Could not create" "$target" 2>/dev/null; exit 1
    fi
    notify-send -a "Code" "New project" "${target/#$HOME/\~}" 2>/dev/null
    ;;
  __BROWSE__)
    # yad is the only GTK chooser installed here (no zenity/kdialog).
    target=$(yad --file --directory --title="Open folder in VS Code" \
                 --filename="$HOME/" --width=900 --height=600 2>/dev/null)
    [ -z "$target" ] && exit 0
    [ -d "$target" ] || { notify-send -a "Code" "Not a directory" "$target" 2>/dev/null; exit 1; }
    ;;
esac

exec code "$target"
