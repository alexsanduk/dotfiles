#!/bin/sh

set -e # -e: exit on error

GITHUB_USERNAME="alexsanduk"

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

eval "$({{- .brew -}}/bin/brew shellenv)"

brew install chezmoi

# POSIX way to get script's dir: https://stackoverflow.com/a/29834779/12156188
script_dir="$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P)"
# exec: replace current process with chezmoi init
chezmoi init --apply --apply ${GITHUB_USERNAME}
