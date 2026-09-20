# This is your fish shell configuration file! You can edit this file to customize your fish shell experience.
# IMPORTANT! The Garuda Linux defaults are set in /usr/share/garuda/garuda-fish-config/config.fish.
# IMPORTANT! Do not edit the defaults file directly, as it will be overwritten during system updates. (You can however read it to learn and get ideas!)
# Instead, you simply add your customizations to this file, and they will override the defaults.

source /usr/share/garuda/garuda-fish-config/config.fish # Do not edit this defaults file!

# -- Insert customizations below this line! --

# Apply pywal (wallpaper-derived) terminal colors to new shells
if status is-interactive
    cat ~/.cache/wal/sequences 2>/dev/null
end


# Keep this at the bottom of the file.
# This shows the "neofetch"/fastfetch output when you open a new terminal.
# If you don't want to see it, simply comment out the line below.
__garuda_fastfetch

# Dynamically find and merge all company configs for kubectx
if test -d ~/.kube/configs
    set -gx KUBECONFIG (string join ":" (find ~/.kube/configs -name "*.yaml"))
end

# >>> conda initialize >>>
# LAZY-LOADED — deliberately not the stock `conda init fish` block.
#
# Measured with `fish --profile-startup`: the stock block's
# `conda shell.fish hook` cost ~1.0s of a 1.99s fish startup. Everything else
# in startup totals 28ms. It ran on every terminal, every SUPER+T, every tab.
#
# PATH and CONDA_EXE are set directly so the environment is identical to
# before; only the expensive hook is deferred. The first `conda` call loads
# the real hook, erases this stub and re-dispatches, so `conda activate` etc.
# behave normally from then on.
#
# If conda is ever removed, delete this whole block (do not re-run conda init,
# or the slow version comes back).
if test -d $HOME/miniconda3
    # condabin ONLY — miniconda3/bin is deliberately kept off the default PATH.
    # It shadowed the system python3, so anything with a
    # "#!/usr/bin/env python3" shebang got conda's interpreter, which lacks
    # the system site-packages. That silently broke syncthing-gtk
    # ("No module named 'gi'") and is a trap for any distro-packaged script.
    # condabin supplies `conda` itself; `conda activate <env>` then puts that
    # env's python/pip on PATH the normal way.
    # Note: this removes bare `pip`/`pip3` from the shell — Arch ships no
    # system pip, and pip outside a venv errors as externally-managed anyway.
    # Use `uv` (already installed) or activate an env first.
    if not contains $HOME/miniconda3/condabin $PATH
        set -gx PATH $HOME/miniconda3/condabin $PATH
    end
    set -gx CONDA_EXE $HOME/miniconda3/bin/conda
    set -gx CONDA_PYTHON_EXE $HOME/miniconda3/bin/python

    function conda --description "lazy-load the real conda hook on first use"
        functions --erase conda
        eval $HOME/miniconda3/bin/conda shell.fish hook | source
        conda $argv
    end
end
# <<< conda initialize <<<
set -gx PATH $PATH $HOME/.krew/bin

# opencode
fish_add_path /home/oluwaseyi/.opencode/bin
