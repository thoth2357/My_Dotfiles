# My_Dotfiles — `macbook`

macOS desktop config: yabai tiling, skhd hotkeys, SketchyBar, fish, Ghostty
and LazyVim, themed Gruvbox Dark (Hard).
Sibling branches: `arch-hyprland` (current Linux desktop, tracked live),
`archlinux` (older i3 + polybar). Each branch is standalone — they share no
history.

This branch is a **snapshot**, not live-tracked: directories sit at the repo
root and are copied (or symlinked) into `~/.config/`.

## Layout

| Path | Goes to | What |
|---|---|---|
| `yabai/` | `~/.config/yabai/` | Tiling WM — `yabairc`, app lists in `yabai_env.sh`, `yabai_restart.sh` |
| `skhd/` | `~/.config/skhd/` | Hotkeys driving yabai |
| `sketchybar/` | `~/.config/sketchybar/` | Menu bar: `sketchybarrc` plus `plugins/` scripts |
| `colors.sh`, `icons.sh` | `~/.config/` | Palette and Nerd Font icons, sourced by SketchyBar |
| `fish/` | `~/.config/fish/` | Shell, with fisher plugins listed in `fish_plugins` |
| `starship.toml` | `~/.config/` | Prompt |
| `ghostty/` | `~/.config/ghostty/` | Terminal (`config` at the root is an older variant) |
| `nvim/` | `~/.config/nvim/` | LazyVim, Gruvbox, fugitive, LSP, WakaTime |
| `micro/`, `ranger/`, `neofetch/`, `timewarrior/` | `~/.config/<name>/` | Editor, file manager, fetch, time tracking |

## Install

```sh
brew install koekeishiya/formulae/yabai koekeishiya/formulae/skhd \
  FelixKratz/formulae/sketchybar
brew install fish starship neovim fzf fd bat eza ranger micro timewarrior
brew install --cask ghostty font-caskaydia-cove-nerd-font font-fantasque-sans-mono-nerd-font

git clone -b macbook https://github.com/thoth2357/My_Dotfiles.git
cd My_Dotfiles
for d in yabai skhd sketchybar fish ghostty nvim micro ranger neofetch timewarrior; do
  ln -sfn "$PWD/$d" ~/.config/$d
done
ln -sf "$PWD/colors.sh" "$PWD/icons.sh" "$PWD/starship.toml" ~/.config/

yabai --start-service && skhd --start-service && brew services start sketchybar
fish -c 'curl -sL https://git.io/fisher | source && fisher update'
```

yabai's scripting addition (`sudo yabai --load-sa`, run from `yabairc`) needs
SIP partly disabled and a passwordless sudoers entry — follow the
[yabai wiki](https://github.com/koekeishiya/yabai/wiki/Installing-yabai-(latest-release)#configure-scripting-addition).
Without it, tiling still works; space focus/move and opacity do not.

## Keys (skhd)

`alt` is the modifier, vim-style directions.

| Keys | Action |
|---|---|
| `alt` + `h/j/k/l` | Focus window |
| `shift+alt` + `h/j/k/l` | Swap window |
| `ctrl+alt` + `h/j/k/l` | Warp (move and re-split) |
| `alt` + `1–7` / `shift+alt` + `1–7` | Focus space / send window to space |
| `shift+alt` + `p/n` | Send window to previous / next space |
| `alt` + `s/g` / `shift+alt` + `s/g` | Focus display / send window to display (west/east) |
| `shift+alt` + `t` | Toggle float (centred) |
| `shift+alt` + `m` | Zoom fullscreen |
| `shift+alt` + `e` | Balance windows |
| `shift+alt` + `r/y/x` | Rotate / mirror y / mirror x |
| `ctrl+alt` + `q/s/r` | Stop / start / restart yabai |
| `alt` + `return` | Ghostty |
| `alt` + `v` | Maccy (clipboard) |
| `alt` + `q/w` | Hide / show the menu bar |

`alt` + mouse drag moves windows, `alt` + right-drag resizes. Ghostty uses a
`cmd+s` prefix (`cmd+s` then `c` new tab, `r` reload, `x` close).

## Notes

- **App rules live in `yabai/yabai_env.sh`**: `apps_mgoff_below` is the list of
  apps yabai leaves floating, `apps_transparent` the apps given 0.97 opacity.
  Edit the lists there, not `yabairc`; `yabai_restart.sh` reapplies them.
- `yabai -m rule --apply` at the end of `yabairc` makes rules apply to windows
  already open after a restart, not just new ones.
- SketchyBar shows Slack and Mail badge counts, Taskwarrior/Timewarrior state,
  and the Flow pomodoro timer; those items stay blank if the app is missing.
- The fish `ls` aliases call `exa`, which Homebrew has replaced with `eza`;
  install `eza` and change `exa` to `eza` in `fish/config.fish`.
- Gruvbox Dark (Hard) is hardcoded in `colors.sh`, Ghostty and Neovim — change
  all three together.
