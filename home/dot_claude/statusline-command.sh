#!/usr/bin/env bash
# Claude Code status line — compact, icon-driven, muted aesthetic
# Icons: JetBrains Mono Nerd Font (v3)

input=$(cat)
parts=()
SEP="$(printf '\033[2m · \033[0m')"
add() { parts+=("$1"); }

# ── Working directory (short form) ───────────────────────────────────────────
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty')
[ -z "$cwd" ] && cwd="$HOME"
dir="${cwd/#$HOME/~}"
# Abbreviate deep paths: ~/a/b/c/d → ~/a/…/c/d (when > 4 components)
dir=$(printf '%s' "$dir" | awk -F/ 'NF>4{print $1"/"$2"/…/"$(NF-1)"/"$NF; next}1')
add "$(printf '\033[38;5;110m \033[38;5;153m%s\033[0m' "$dir")"

# ── Git branch ────────────────────────────────────────────────────────────────
branch=$(printf '%s' "$input" | jq -r '.worktree.branch // empty')
[ -z "$branch" ] && branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
repo=$(printf '%s' "$input" | jq -r '.workspace.repo | if . then .owner + "/" + .name else empty end')
if [ -n "$branch" ]; then
  if [ -n "$repo" ]; then
    add "$(printf '\033[38;5;179m %s\033[2m (%s)\033[0m' "$branch" "$repo")"
  else
    add "$(printf '\033[38;5;179m %s\033[0m' "$branch")"
  fi
fi

# ── Model (strip leading "Claude " for brevity) ───────────────────────────────
model=$(printf '%s' "$input" | jq -r '.model.display_name // empty' | sed 's/^Claude //')
[ -n "$model" ] && add "$(printf '\033[38;5;109m󰧑 %s\033[0m' "$model")"

# ── Context window usage (green → amber → red) ────────────────────────────────
ctx=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$ctx" ]; then
  pct=$(printf '%.0f' "$ctx")
  if   [ "$pct" -ge 80 ]; then cc='38;5;167'   # muted red
  elif [ "$pct" -ge 50 ]; then cc='38;5;179'   # amber
  else                          cc='38;5;71'    # muted green
  fi
  add "$(printf '\033[%smctx:%d%%\033[0m' "$cc" "$pct")"
fi

# ── Subscription rate limits (dim; only when the API provides them) ───────────
five=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
rate=""
[ -n "$five" ] && rate="5h:$(printf '%.0f' "$five")%"
[ -n "$week" ] && rate="${rate:+$rate }7d:$(printf '%.0f' "$week")%"
[ -n "$rate"  ] && add "$(printf '\033[2m%s\033[0m' "$rate")"

# ── Open PR for current branch ────────────────────────────────────────────────
pr_num=$(printf '%s' "$input" | jq -r '.pr.number // empty')
if [ -n "$pr_num" ]; then
  pr_state=$(printf '%s' "$input" | jq -r '.pr.review_state // "open"')
  case "$pr_state" in
    approved)           pcol='38;5;71'  ;;
    changes_requested)  pcol='38;5;167' ;;
    draft)              pcol='2'        ;;
    *)                  pcol='38;5;109' ;;
  esac
  add "$(printf '\033[%sm #%s\033[0m' "$pcol" "$pr_num")"
fi

# ── Reasoning effort (when the model exposes it) ──────────────────────────────
effort=$(printf '%s' "$input" | jq -r '.effort.level // empty')
[ -n "$effort" ] && add "$(printf '\033[2m %s\033[0m' "$effort")"

# ── Render ────────────────────────────────────────────────────────────────────
out=""
for p in "${parts[@]}"; do
  [ -z "$out" ] && out="$p" || out="${out}${SEP}${p}"
done
printf '%s\n' "$out"
