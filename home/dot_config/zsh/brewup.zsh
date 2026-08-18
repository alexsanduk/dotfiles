# Manual, prompted package updates.
#
# Replaces `brew autoupdate` (a launchd job that upgraded a fixed allowlist silently
# every 24h and at every login). Instead, the first interactive shell opened after 24h
# have passed asks whether to update. Answering no — or letting the prompt time out —
# resets the clock, so you are asked at most once a day.
#
#   brewup            run the update now, ignoring the clock
#   BREWUP_DISABLE=1  suppress the startup prompt entirely
#
# Note this is genuinely manual: if you never open a terminal, or always answer no,
# brew packages never update. Apps with their own updaters (Chrome, 1Password, VS Code)
# are unaffected either way — they keep updating themselves.

zmodload -F zsh/datetime p:EPOCHSECONDS

BREWUP_STAMP="${XDG_STATE_HOME:-$HOME/.local/state}/brewup/last-prompt"
BREWUP_INTERVAL=$(( 24 * 60 * 60 ))

brewup() {
  # --yes: Homebrew's "ask mode" is the default, and would otherwise prompt a second
  # time immediately after you answered the prompt above.
  #
  # No --greedy: that additionally pulls in casks pinned to `version :latest`, whose
  # recorded versions drift far out of sync with reality (brew still thinks zoom is
  # 5.15 while the app self-updated to 7.x), causing large redundant re-downloads and
  # force-quitting running apps.
  brew update && brew upgrade --yes && brew cleanup || return

  # Dotfiles are only ever *reported*, never applied. Pulling is safe, but rewriting the
  # rc files of the shell you're sitting in should stay a deliberate act.
  print -P '\n%F{blue}==>%f %BDotfiles%b'
  if ! chezmoi git -- pull --ff-only >/dev/null 2>&1; then
    # Usually uncommitted local changes; also diverged history or no network.
    print -P '%F{242}pull skipped — run %f%F{cyan}chezmoi git -- pull --ff-only%f%F{242} to see why%f'
  fi

  local pending
  if ! pending=$(chezmoi status 2>/dev/null); then
    # private_dot_gitconfig.tmpl calls onepasswordRead, which is evaluated at render
    # time, so a locked vault makes `chezmoi status` fail. Don't dump that at startup.
    print -P '%F{242}skipped — chezmoi status failed (1Password locked?)%f'
  elif [[ -z $pending ]]; then
    print -P '%F{green}up to date%f'
  else
    print -P '%F{yellow}pending changes:%f'
    print -r -- "$pending"
    print -P 'review with %F{cyan}chezmoi diff%f, apply with %F{cyan}chezmoi apply%f'
  fi
}

_brewup_prompt() {
  [[ -o interactive && -t 0 ]] || return
  [[ -z $BREWUP_DISABLE ]] || return

  local now=$EPOCHSECONDS last=0
  [[ -r $BREWUP_STAMP ]] && last=$(<$BREWUP_STAMP)
  (( now - last < BREWUP_INTERVAL )) && return

  # Stamp *before* prompting, not after. Opening several tabs at once must produce one
  # prompt rather than one per tab, and must never race two `brew upgrade` runs into
  # brew's lock.
  mkdir -p -- "${BREWUP_STAMP:h}" && print -r -- $now > "$BREWUP_STAMP"

  local reply
  print -Pn '%F{yellow}Check for package updates?%f [y/N] (15s) '
  if ! read -t 15 -k 1 reply; then
    print -P '\n%F{242}timed out — asking again tomorrow%f'
    return
  fi
  print
  if [[ $reply != [yY] ]]; then
    print -P '%F{242}skipped — asking again tomorrow (run %f%F{cyan}brewup%f%F{242} anytime)%f'
    return
  fi
  brewup
}

_brewup_prompt
unfunction _brewup_prompt
