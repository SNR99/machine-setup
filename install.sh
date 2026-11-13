#!/bin/bash
# Set up how the terminal behaves: prompt, key bindings, suggestions,
# highlighting, fuzzy finder, plus the tool aliases and the `reload` and `reap`
# commands. Nothing else.
#
#   ./install.sh
#
# The files are copied into ~/.config/zsh, so this folder can be deleted
# afterwards.
#
# Safe to run again at any time: every step is skipped if already done.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
CONF="$HOME/.config/zsh"
ZSHRC="$HOME/.zshrc"

# ── 1. The Homebrew tools the two files use ──────────────────────────────────
BREW="$(command -v brew || true)"
[[ -z "$BREW" && -x /opt/homebrew/bin/brew ]] && BREW=/opt/homebrew/bin/brew
if [[ -z "$BREW" ]]; then
  echo "Homebrew is not installed. Install it from https://brew.sh, then run this again."
  exit 1
fi
# --no-upgrade: install what is missing, never upgrade what is already there.
"$BREW" bundle --no-upgrade --file "$REPO/Brewfile"

# ── 2. Put each file in ~/.config/zsh, and make ~/.zshrc load it ─────────────
# ~/.zshrc gets one line at the end per file, only if no line there mentions
# the file yet; nothing else in ~/.zshrc is touched. Before the first line is
# added, ~/.zshrc is copied to ~/.zshrc.machine-setup-<time>.bak.
mkdir -p "$CONF"
STAMP="$(date +%Y%m%d-%H%M%S)"
ZSHRC_BACKED_UP=

# Copy ~/.zshrc aside once per run, just before it is first changed
# (there is nothing to copy if this run is creating it)
backup_zshrc() {
  [[ -n "$ZSHRC_BACKED_UP" ]] && return 0
  ZSHRC_BACKED_UP=1
  [[ -f "$ZSHRC" ]] || return 0
  cp -p "$ZSHRC" "$ZSHRC.machine-setup-$STAMP.bak"
  echo "backed up ~/.zshrc to ~/.zshrc.machine-setup-$STAMP.bak"
}

install_file() {
  local name="$1" comment="$2"
  local src="$REPO/$name" dest="$CONF/$name"

  if [[ -f "$dest" && ! -L "$dest" ]] && cmp -s "$dest" "$src"; then
    echo "ok        ~/.config/zsh/$name (up to date)"
  else
    # A different file you may have edited is kept; an old link is just replaced.
    if [[ -f "$dest" && ! -L "$dest" ]]; then
      mv "$dest" "$dest.backup-$STAMP"
      echo "backed up existing file to $dest.backup-$STAMP"
    fi
    rm -f "$dest"
    cp "$src" "$dest"
    echo "copied    ~/.config/zsh/$name"
  fi

  if [[ -f "$ZSHRC" ]] && grep -qF "$name" "$ZSHRC"; then
    echo "ok        ~/.zshrc already loads $name"
  else
    backup_zshrc
    printf '\n# %s\n[ -f ~/.config/zsh/%s ] && source ~/.config/zsh/%s\n' "$comment" "$name" "$name" >> "$ZSHRC"
    echo "added     one line to ~/.zshrc for $name"
  fi
}

install_file interactive.zsh "Prompt, shell options, fzf, autosuggestions, syntax highlighting"
install_file extras.zsh      "Tool aliases, reload and reap"

echo
echo "Done. Open a new terminal to see it. This folder is no longer needed and can be deleted."
