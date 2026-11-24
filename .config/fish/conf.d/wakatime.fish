# WakaTime heartbeats for interactive fish (Ghostty). One heartbeat per command,
# entity = command name, project = git repo name (or cwd name). Sent in the background.
status is-interactive; or exit
set -q WAKATIME_CLI; or set -g WAKATIME_CLI $HOME/.wakatime/wakatime-cli
test -x $WAKATIME_CLI; or exit

function __wakatime_heartbeat --on-event fish_preexec
    set -l cmd (string split -f1 ' ' -- (string trim -- $argv[1]))
    test -n "$cmd"; or return
    set -l root (command git rev-parse --show-toplevel 2>/dev/null); or set root $PWD
    $WAKATIME_CLI --write --plugin "ghostty-fish-wakatime/1.0" \
        --entity-type app --entity $cmd --category coding \
        --project (path basename $root) --language Shell >/dev/null 2>&1 &
    disown 2>/dev/null
end
