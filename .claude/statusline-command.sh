#!/usr/bin/env bash
# Claude Code statusLine, translated from ~/.config/starship.toml
# (starship is initialized from /usr/share/garuda/garuda-fish-config/config.fish,
# which is sourced by ~/.config/fish/config.fish)

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')
[ -z "$cwd" ] && cwd="$PWD"
model=$(echo "$input" | jq -r '.model.display_name // empty')

user=$(whoami)
host=$(hostname -s 2>/dev/null)

# --- directory: [directory] truncate_to_repo = true, truncation_length = 0 ---
dir_display="$cwd"
if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  repo_root=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
  repo_name=$(basename "$repo_root")
  rel=$(realpath --relative-to="$repo_root" "$cwd" 2>/dev/null)
  if [ -n "$repo_name" ]; then
    if [ "$rel" = "." ] || [ -z "$rel" ]; then
      dir_display="$repo_name"
    else
      dir_display="$repo_name/$rel"
    fi
  fi
fi

# --- git_branch / git_status: ahead/behind counts ---
branch=""
ab=""
gitstatus=$(git -C "$cwd" --no-optional-locks status --porcelain=v2 --branch 2>/dev/null)
if [ -n "$gitstatus" ]; then
  branch=$(echo "$gitstatus" | awk '/^# branch\.head/{print $3}')
  abline=$(echo "$gitstatus" | awk '/^# branch\.ab/{print $3, $4}')
  if [ -n "$abline" ]; then
    ahead=$(echo "$abline" | awk '{print $1}' | tr -d '+')
    behind=$(echo "$abline" | awk '{print $2}' | tr -d '-')
    [ -n "$ahead" ] && [ "$ahead" != "0" ] && ab="${ab}⇡${ahead}"
    [ -n "$behind" ] && [ "$behind" != "0" ] && ab="${ab}⇣${behind}"
  fi
fi

# --- kubernetes: shown when a context is active and kubectl is fast/available ---
k8s=""
if command -v kubectl >/dev/null 2>&1; then
  # There is no ~/.kube/config on this machine; the context lives in
  # ~/.kube/configs/*.yaml and fish exports KUBECONFIG. Claude Code does not
  # necessarily inherit that (e.g. launched from a desktop entry), so rebuild
  # it the same way ~/.config/waybar/scripts/cluster.sh does, or this segment
  # silently never renders.
  if [ -z "$KUBECONFIG" ] && [ -d "$HOME/.kube/configs" ]; then
    KUBECONFIG=$(find "$HOME/.kube/configs" -name '*.yaml' | paste -sd:)
    export KUBECONFIG
  fi
  ctx=$(timeout 0.3 kubectl config current-context 2>/dev/null)
  [ -n "$ctx" ] && k8s="$ctx"
fi

# Colors (dimmed variants used since the statusline area already renders dim)
RED_BOLD=$'\033[1;31m'
RED_DIM=$'\033[2;31m'
PURPLE=$'\033[2;35m'
CYAN_BOLD=$'\033[1;36m'
WHITE_DIM=$'\033[2;37m'
BLUE_DIM=$'\033[2;34m'
RESET=$'\033[0m'

# --- [username]@[hostname] in [kubernetes] [directory] [git_branch git_status] ---
line1="${RED_BOLD}╭─${user}${RESET}@${RED_DIM}${host}${RESET} in "
[ -n "$k8s" ] && line1="${line1}${CYAN_BOLD}[󱃾 ${k8s}]${RESET} "
line1="${line1}${PURPLE}${dir_display}${RESET}"
[ -n "$branch" ] && line1="${line1} ${BLUE_DIM} ${branch}${RESET}"
[ -n "$ab" ] && line1="${line1} ${WHITE_DIM}${ab}${RESET}"

# --- [character] success_symbol, followed by the active Claude model ---
line2="${RED_BOLD}╰─λ${RESET} ${model}"

printf '%s\n%s' "$line1" "$line2"
