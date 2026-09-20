# This is your bash shell configuration file! You can edit this file to customize your bash shell experience.
# IMPORTANT! The Garuda Linux defaults are set in /usr/share/garuda/garuda-bash-config/bashrc.
# IMPORTANT! Do not edit the defaults file directly, as it will be overwritten during system updates. (You can however read it to learn and get ideas!)
# Instead, you simply add your customizations to this file, and they will override the defaults.
source /usr/share/garuda/garuda-bash-config/bashrc

# -- Insert customizations below this line! --

# >>> conda initialize >>>
# LAZY + condabin-only. Deliberately not the stock `conda init` block:
#  * the stock hook costs ~1s of shell startup (measured in fish: 997ms of
#    1986ms total), and
#  * it put miniconda3/bin ahead of /usr/bin, shadowing the system python3 so
#    "#!/usr/bin/env python3" scripts got conda's interpreter and lost system
#    site-packages (this silently broke syncthing-gtk: "No module named 'gi'").
# condabin supplies `conda`; `conda activate <env>` adds that env's python/pip
# to PATH normally. Do not re-run `conda init` or the slow version returns.
if [ -d "$HOME/miniconda3" ]; then
    case ":$PATH:" in
        *":$HOME/miniconda3/condabin:"*) ;;
        *) export PATH="$HOME/miniconda3/condabin:$PATH" ;;
    esac
    export CONDA_EXE="$HOME/miniconda3/bin/conda"
    export CONDA_PYTHON_EXE="$HOME/miniconda3/bin/python"
    conda() {
        unset -f conda
        eval "$("$HOME/miniconda3/bin/conda" shell.bash hook)"
        conda "$@"
    }
fi
# <<< conda initialize <<<


. "$HOME/.local/share/../bin/env"

# Dotfiles bare repo: git dir ~/.dotfiles, work tree $HOME (branch arch-hyprland).
# The tracked files are the live configs — see ~/README.md
alias config='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
