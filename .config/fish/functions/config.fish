# Dotfiles bare repo: git dir at ~/.dotfiles, work tree at $HOME, so the
# tracked files ARE the live configs. Branch: arch-hyprland.
#   config status / config add <path> / config commit -m ... / config push
function config --wraps git --description "git for the ~/.dotfiles bare repo (work tree = \$HOME)"
    git --git-dir=$HOME/.dotfiles --work-tree=$HOME $argv
end
