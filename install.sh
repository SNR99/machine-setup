#!/bin/bash
# Set up how the terminal behaves: prompt, key bindings, suggestions,
# highlighting, fuzzy finder. Nothing else.
#
#   ./install.sh
#
# Safe to run again at any time: every step is skipped if already done.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
SRC="$REPO/interactive.zsh"
DEST="$HOME/.config/zsh/interactive.zsh"
ZSHRC="$HOME/.zshrc"
SOURCE_LINE='[ -f ~/.config/zsh/interactive.zsh ] && source ~/.config/zsh/interactive.zsh'

# ── 1. The six Homebrew tools interactive.zsh uses ───────────────────────────
BREW="$(command -v brew || true)"
[[ -z "$BREW" && -x /opt/homebrew/bin/brew ]] && BREW=/opt/homebrew/bin/brew
if [[ -z "$BREW" ]]; then
  echo "Homebrew is not installed. Install it from https://brew.sh, then run this again."
  exit 1
fi
# --no-upgrade: install what is missing, never upgrade what is already there.
"$BREW" bundle --no-upgrade --file "$REPO/Brewfile"

# ── 2. Link interactive.zsh into ~/.config/zsh ───────────────────────────────
# A link, so the copy in this repo is the one zsh reads.
mkdir -p "$(dirname "$DEST")"
if [[ -L "$DEST" && "$(readlink "$DEST")" == "$SRC" ]]; then
  echo "ok        ~/.config/zsh/interactive.zsh"
else
  if [[ -e "$DEST" || -L "$DEST" ]]; then
    BACKUP="$DEST.backup-$(date +%Y%m%d-%H%M%S)"
    mv "$DEST" "$BACKUP"
    echo "backed up existing file to $BACKUP"
  fi
  ln -s "$SRC" "$DEST"
  echo "linked    ~/.config/zsh/interactive.zsh"
fi

# ── 3. Make ~/.zshrc load it ─────────────────────────────────────────────────
# Adds one line at the end, only if no line mentions interactive.zsh yet.
# Nothing else in ~/.zshrc is touched.
if [[ -f "$ZSHRC" ]] && grep -q 'interactive\.zsh' "$ZSHRC"; then
  echo "ok        ~/.zshrc already loads it"
else
  printf '\n# Prompt, shell options, fzf, autosuggestions, syntax highlighting\n%s\n' "$SOURCE_LINE" >> "$ZSHRC"
  echo "added     one line to ~/.zshrc"
fi

echo
echo "Done. Open a new terminal to see it."
