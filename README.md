# My_Dotfiles — `arch-hyprland`

Arch Linux + Hyprland (Wayland) desktop config.
Sibling branches: `archlinux` (older i3 + polybar), `macbook`.
Each branch is standalone — they share no history.

## Layout

Paths are `$HOME`-relative, because this branch is tracked live (see below)
rather than copied. The other branches are snapshots, so their layout differs.

| Path | What |
|---|---|
| `.config/hypr/` | Hyprland (**Lua** config, not `hyprland.conf`), hypridle, hyprlock |
| `.config/waybar/` | Bar config, CSS, and the module scripts it calls |
| `.config/swaync/` | Notifications |
| `.config/fish/` | Shell |
| `.config/starship.toml` | Prompt |
| `.config/wal/templates/` | pywal templates — **the source of the colour scheme** |
| `.config/waypaper/` | Wallpaper picker + the pywal refresh pipeline |
| `.config/ghostty/`, `rofi/`, `wlogout/`, `cursor-clip/` | Terminal, launcher, logout, clipboard |
| `.config/gtk-3.0/`, `gtk-4.0/`, `qt5ct/`, `qt6ct/` | Toolkit theming |

## Theming

Colours are **wallpaper-derived via pywal**, not hardcoded. Changing wallpaper
through `waypaper` runs `wal-refresh.sh`, which regenerates everything from
`.config/wal/templates/` into `~/.cache/wal/` and reloads the affected apps.

To theme a new app, add a template there — do not hardcode hex values; they
drift out of key on the next wallpaper change.

Text uses a three-tier emphasis scale over pywal's foreground, at higher
opacities than the textbook Material 87/60/38. That scale assumes an opaque
surface; these are translucent over blurred wallpaper, where the muted tier
measured 1.2–2.3:1 contrast — below the WCAG floor.

## Display scaling

Built for a ~157 DPI panel at Hyprland `scale = 1`. UI defaults assume 96 DPI,
so sizes here are deliberately larger than typical example configs. GTK apps
use `text-scaling-factor = 1.25`; Waybar is sized explicitly in px, because GTK
text scaling does not affect its CSS pixel sizes.

## Gotchas worth keeping

- `conda init` blocks in `fish/config.fish`, `.zshrc` and `.bashrc` are
  **lazy-loaded** by hand. The stock block cost ~1s of shell startup. Re-running
  `conda init` reverts it.
- `miniconda3/bin` is kept **off** the default PATH (only `condabin`), so
  `#!/usr/bin/env python3` scripts get the system interpreter.
- Waybar's clock uses `%I`, not `%-I` — its chrono library rejects the no-pad flag.
- Starship custom modules pin `shell = ["/bin/sh"]` with **no** `-c`: Starship
  feeds the command on stdin, and `$STARSHIP_SHELL` is fish.
- A few Waybar modules are machine-local and not tracked. Their definitions
  remain in `config.jsonc`; with no script present they produce no output and
  simply do not render, and their CSS is still in `style.css`.

## How this repo is managed

Bare repo: git dir at `~/.dotfiles`, work tree at `$HOME`, so tracked files
**are** the live configs — no copying, no drift.

```fish
config status
config add .config/waybar/style.css
config commit -m "waybar: tweak"
config push
```

`config` is an alias for `git --git-dir=$HOME/.dotfiles --work-tree=$HOME`,
defined for fish, zsh and bash.

### Restoring on a new machine

```sh
git clone --bare <this repo> $HOME/.dotfiles
git --git-dir=$HOME/.dotfiles --work-tree=$HOME checkout arch-hyprland
git --git-dir=$HOME/.dotfiles --work-tree=$HOME config status.showUntrackedFiles no
```

### Tracking rules

`~/.gitignore` denies everything by default and allow-lists only the config
paths this repo tracks. With a whole home directory as the work tree that is
the difference between a dotfiles repo and an accident.

Consequence: **a new config directory is not tracked until it is allow-listed.**
Fail-closed on purpose. `status.showUntrackedFiles` is `no`, so the rest of
`$HOME` never appears as noise.
