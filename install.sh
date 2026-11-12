#!/bin/bash
# Set up how the terminal behaves: prompt, key bindings, suggestions,
# highlighting, fuzzy finder, plus the `reload` and `reap` commands.
# Nothing else.
#
#   ./install.sh
#
# Safe to run again at any time: every step is skipped if already done.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
CONF="$HOME/.config/zsh"
ZSHRC="$HOME/.zshrc"

# ── 1. The six Homebrew tools interactive.zsh uses ───────────────────────────
BREW="$(command -v brew || true)"
[[ -z "$BREW" && -x /opt/homebrew/bin/brew ]] && BREW=/opt/homebrew/bin/brew
if [[ -z "$BREW" ]]; then
  echo "Homebrew is not installed. Install it from https://brew.sh, then run this again."
  exit 1
fi
# --no-upgrade: install what is missing, never upgrade what is already there.
"$BREW" bundle --no-upgrade --file "$REPO/Brewfile"

# ── 2. Link each file into ~/.config/zsh, and make ~/.zshrc load it ──────────
# A link, so the copy in this repo is the one zsh reads. ~/.zshrc gets one line
# at the end per file, only if no line there mentions the file yet; nothing
# else in ~/.zshrc is touched.
mkdir -p "$CONF"
STAMP="$(date +%Y%m%d-%H%M%S)"

install_file() {
  local name="$1" comment="$2"
  local src="$REPO/$name" dest="$CONF/$name"

  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    echo "ok        ~/.config/zsh/$name"
  else
    if [[ -e "$dest" || -L "$dest" ]]; then
      mv "$dest" "$dest.backup-$STAMP"
      echo "backed up existing file to $dest.backup-$STAMP"
    fi
    ln -s "$src" "$dest"
    echo "linked    ~/.config/zsh/$name"
  fi

  if [[ -f "$ZSHRC" ]] && grep -qF "$name" "$ZSHRC"; then
    echo "ok        ~/.zshrc already loads $name"
  else
    printf '\n# %s\n[ -f ~/.config/zsh/%s ] && source ~/.config/zsh/%s\n' "$comment" "$name" "$name" >> "$ZSHRC"
    echo "added     one line to ~/.zshrc for $name"
  fi
}

install_file interactive.zsh "Prompt, shell options, fzf, autosuggestions, syntax highlighting"
install_file extras.zsh      "reload and reap"

echo
echo "Done. Open a new terminal to see it."
