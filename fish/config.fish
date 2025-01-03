if status --is-interactive
    source (starship init fish --print-full-init | psub)
end

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /Users/ghost/anaconda3/bin/conda
    eval /Users/ghost/anaconda3/bin/conda "shell.fish" "hook" $argv | source
end
# <<< conda initialize <<<

function history
    builtin history --show-time='%F %T '
end

#git aliases
function git-start --argument username email #function to choose the git user details to use for respective projects
    
    # Set the Git config values
    git config user.name "$username"
    git config user.email "$email"

    echo "Git user.name set to '$username'"
    echo "Git user.email set to '$email'"
end

alias cm="gitmoji -c"
alias unstage="git restore --staged ."
alias stage="git add ."
alias forcepush="git push -f"
alias pull="git pull"
alias switchaccount="gh auth login"
alias ghs="git status"

alias cat 'bat --style header --style snip --style changes --style header'

# Replace ls with exa
alias ls 'exa -alh --color=always --group-directories-first --icons' # preferred listing
alias la 'exa -a --color=always --group-directories-first --icons'  # all files and dirs
alias ll 'exa -l --color=always --group-directories-first --icons'  # long format
alias lt 'exa -aT --color=always --group-directories-first --icons' # tree listing
alias l. 'exa -ald --color=always --group-directories-first --icons .*' # show only dotfiles

alias wget 'wget -c'
alias cat 'bat'

#servers
alias server1 'ssh root@144.126.159.4'  # 
alias server2 'ssh root@144.126.159.250'  # statarchive,workspace reseller
alias server3 'ssh seyi@65.21.50.65'  # contentidea
alias server4 'ssh seyi@79.143.183.23' #contabo gbagbo automation


fzf_configure_bindings --directory=\cf --git_log=\cl --git_status=\cg --processes=\cp

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/ghost/google-cloud-sdk/path.fish.inc' ]; . '/Users/ghost/google-cloud-sdk/path.fish.inc'; end
