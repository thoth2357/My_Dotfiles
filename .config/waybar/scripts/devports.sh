#!/usr/bin/env bash
# Local dev servers that are actually listening, for waybar.
#
# A naive "list listening ports" module is useless here: VS Code alone holds
# several random high ports for its own IPC, and there's ollama, syncthing and
# sshd besides. So this filters to ports a dev server would plausibly be on and
# drops known background noise by process name.
#
# Empty output hides the module — nothing serving, nothing shown.

NL=$'\n'

# Processes that listen but are never "the thing I'm working on".
NOISE='code|syncthing|sshd|ollama|dockerd|containerd|tailscaled|systemd|cupsd|avahi'
# ss can only show process names for our own sockets, so services running as
# another user (ollama, system daemons) arrive as "?" and slip the name filter.
# Screen those by port. Unknown-process ports that AREN'T on this list are kept
# on purpose — that's usually a docker-published container port, which counts.
NOISE_PORTS='11434|8384|22000|631|5353|5355|323|53'

rows=$(ss -tlnpH 2>/dev/null | awk '
{
    addr = $4
    # strip IPv6 brackets and the interface part, keep the port
    n = split(addr, a, ":")
    port = a[n]
    host = substr(addr, 1, length(addr) - length(port) - 1)
    # only loopback / all-interfaces; skip link-local noise
    if (host != "127.0.0.1" && host != "0.0.0.0" && host != "*" && host != "[::]" && host != "::") next
    proc = "?"
    if (match($0, /users:\(\("[^"]+/)) {
        proc = substr($0, RSTART + 9, RLENGTH - 9)
        gsub(/"/, "", proc)
    }
    print port, proc
}' | sort -un -k1,1)

[ -z "$rows" ] && exit 0

listed=""
count=0
while read -r port proc; do
    [ -z "$port" ] && continue
    # dev-server range: the ports people actually bind apps to
    if [ "$port" -lt 1024 ] || [ "$port" -gt 30000 ]; then continue; fi
    printf '%s' "$proc" | grep -qiE "^($NOISE)$" && continue
    printf '%s' "$port" | grep -qE "^($NOISE_PORTS)$" && continue
    count=$((count + 1))
    listed="${listed}${NL}  ${port}  ${proc}"
done <<< "$rows"

[ "$count" -eq 0 ] && exit 0

# Show the lowest port as the headline — that's almost always the app server.
first=$(printf '%s' "$listed" | sed -n '2p' | awk '{print $1}')
if [ "$count" -eq 1 ]; then
    text=":${first}"
else
    text=":${first} +$((count - 1))"
fi

tip="Listening dev ports:${listed}"
jq -nc --arg t "$text" --arg tip "$tip" '{text:$t, tooltip:$tip, class:"serving"}'
