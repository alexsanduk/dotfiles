# Dotfiles

Personal macOS dotfiles, managed with [chezmoi](https://github.com/twpayne/chezmoi).

## What's in here

- **Shell** — zsh with native history/completion (no oh-my-zsh), [Starship](https://starship.rs) prompt
- **Terminal** — [Ghostty](https://ghostty.org) with Gruvbox Dark Hard + JetBrainsMono Nerd Font
- **Editor** — Neovim via [LazyVim](https://www.lazyvim.org), pulled from a sibling repo
- **Packages** — a [`~/.Brewfile`](home/dot_Brewfile) installed via `brew bundle`
- **Auto-updates** — `brew autoupdate` (domt4 tap) runs on boot and every 24h
- **macOS** — Dock arrangement via [dockutil](https://github.com/kcrawford/dockutil)
- **Git** — config + global gitignore; signs commits with a 1Password SSH key

## Install on a fresh Mac

```sh
./install.sh
```

That bootstraps Homebrew → chezmoi → applies this repo. Edit `install.sh` first to point at the right GitHub username if you're forking.

## Day-to-day

```sh
chezmoi cd            # jump into the source dir (git repo)
chezmoi diff          # preview pending changes
chezmoi apply         # apply pending changes
chezmoi edit ~/.zshrc # edit a managed file (auto-applies on exit)
```

## Package management

Edit [`home/dot_Brewfile`](home/dot_Brewfile), then `chezmoi apply`. The
`run_onchange_after_install-packages.sh.tmpl` script hashes the Brewfile so
it only re-runs on actual changes. It also prints a dry-run of anything
installed locally but not in the Brewfile, with the exact command to clean
up.

## Layout

```
home/
  dot_Brewfile                 → ~/.Brewfile
  dot_zshrc.tmpl               → ~/.zshrc
  dot_fzf.zsh.tmpl             → ~/.fzf.zsh
  dot_config/
    ghostty/config             → ~/.config/ghostty/config
    starship.toml              → ~/.config/starship.toml
  private_dot_gitconfig.tmpl   → ~/.gitconfig (uses 1Password CLI)
  private_dot_gitignore        → ~/.gitignore (global)
  private_dot_ssh/
    private_config             → ~/.ssh/config
  run_onchange_after_install-packages.sh.tmpl   # brew bundle + autoupdate
  run_onchange_after_setup_os.sh.tmpl           # macOS Dock + prefs
  .chezmoiexternal.toml        # external dirs (LazyVim)
```
