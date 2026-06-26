# Working in this repo

Personal macOS dotfiles managed by [chezmoi](https://github.com/twpayne/chezmoi). The chezmoi source tree lives at the repo root; rendered files land in `$HOME`.

## chezmoi naming rules that matter here

- `dot_foo` → `~/.foo`
- `private_dot_foo` → `~/.foo` with `0600` perms
- `foo.tmpl` → rendered as a Go template, with data from `.chezmoi.toml.tmpl`
- `run_onchange_after_<name>.sh.tmpl` → script that re-runs **only when its rendered content changes** (we hash the Brewfile inside the script to trigger reruns), and runs **after** file targets are applied
- `run_onchange_before_*` → runs **before** file targets — **do not use here**. We hit a bug where `before_install-packages` ran `brew bundle` against the stale `~/.Brewfile` because chezmoi hadn't written the new one yet. Always use `after_`.
- `empty_dot_foo` → empty marker file (e.g. `.hushlogin`)

## Package management

Single source of truth: [`home/dot_Brewfile`](home/dot_Brewfile). The install script:

1. Runs `brew bundle --global`
2. Starts `brew autoupdate` (from the `domt4/autoupdate` tap, with `--immediate` so it also runs at boot)
3. Prints a dry-run of drift (`brew bundle cleanup --global`) and the command to remove it

The script's first line is a hash comment of the Brewfile (`# Brewfile hash: {{ include "dot_Brewfile" | sha256sum }}`) — that's what makes `run_onchange_*` notice changes.

Don't add inline `brew install` lines anywhere else. If something needs installing, it goes in the Brewfile.

## Script ordering

Three `run_onchange_after_*.sh.tmpl` scripts execute in alphabetical order on every apply where their content has changed:

1. `install-packages` — brew bundle, autoupdate
2. `setup_os` — Dock layout via dockutil, `defaults write` for system prefs

If you add a third script that depends on packages, name it so it sorts after `install-packages`.

## Where things live

| File | Purpose |
|---|---|
| `.chezmoi.toml.tmpl` | Sets the `brew` data var (`/opt/homebrew` on arm64, `/usr/local` on Intel) |
| `.chezmoiexternal.toml` | Pulls LazyVim into `~/.config/nvim` |
| `home/dot_Brewfile` | All brew/cask/tap entries |
| `home/dot_zshrc.tmpl` | zsh config — history, completions, aliases, starship init |
| `home/dot_fzf.zsh.tmpl` | fzf shell integration (we own this file; do **not** also run `fzf install`, it overwrites) |
| `home/dot_config/ghostty/config` | Terminal: Gruvbox Dark Hard, JetBrainsMono Nerd Font |
| `home/dot_config/starship.toml` | Prompt: minimal, AWS module disabled, Python module venv-aware |
| `home/private_dot_gitconfig.tmpl` | Uses `onepasswordRead` for name/email/signing key |
| `home/private_dot_ssh/private_config` | Routes `IdentityAgent` to 1Password SSH agent |

## Common pitfalls

- **Two owners on one file.** `fzf install` rewrites `~/.fzf.zsh`. We let the chezmoi template own it instead. Don't add `fzf install` back into any script.
- **External modifications.** If chezmoi says "X has changed since chezmoi last wrote it", the safest reset is `rm ~/X && chezmoi apply` — the template re-renders cleanly.
- **Stale lock.** `chezmoi: timeout obtaining persistent state lock` usually means a previous `chezmoi apply` is still running (often compiling something). `pgrep -fl chezmoi` first.
- **Untrusted tap.** New third-party taps need `brew trust <tap>` before brew will load them. Currently relevant for `domt4/autoupdate`.

## Testing changes

Before committing, always:

```sh
chezmoi diff           # see what would change in $HOME
chezmoi apply -v       # dry-run-ish: verbose apply
```

For Brewfile changes specifically, the install script's drift report at the end of `chezmoi apply` is the best signal that the new state is clean.
