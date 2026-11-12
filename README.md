# mac-setup

How my terminal behaves, without oh-my-zsh or powerlevel10k: the prompt, key
bindings, suggestions, highlighting and fuzzy finder, plus a few small commands.
Nothing else. It is not a full machine setup.

## What you get

Two files. `interactive.zsh` holds the terminal behaviour:

- **Prompt:** the current folder on one line and `❯` on the next, green or red
  by the last command's result. Once a command is entered, its prompt collapses
  to a bare `❯`.
- **Empty Enter** does nothing.
- **Suggestions and highlighting:** grey suggestions from history as you type
  (→ accepts), and commands coloured green or red.
- **History:** Up/Down search by what is already typed; duplicates are not saved.
- **Fuzzy finder:** Ctrl-R searches history; Ctrl-T picks a file with a preview.
- **Completion:** ignores case, coloured, grouped under headings.
- **Esc Esc** puts `sudo` in front of the current or previous command.
- **Folders:** type a folder name to `cd` into it; `...` and `....` go up two
  and three levels.

`extras.zsh` holds a few commands:

- **`ls`, `ll`, `lt`** list files through `eza`: folders first, `ll` with details
  and hidden files, `lt` as a tree two levels deep (`lt -L 4` for deeper).
- **`cat`, `grep`, `find`** run `bat`, `rg` and `fd` instead.
- **`c`** copies to the clipboard: `pwd | c`.
- **Mouse reset:** before each prompt, mouse tracking left on by a dropped SSH
  session is turned off, so clicks don't print junk.
- **`reload`** restarts the shell, so config changes take effect.
- **`reap`** opens a picker listing the TCP ports your processes are
  listening on, plus your orphaned processes that hold no port. Type to filter,
  Tab to mark several, Enter to stop them, Esc to leave. Piped, it prints the
  list instead.

## Install

1. Install [Homebrew](https://brew.sh).
2. Clone this repo anywhere you like and go into it.
3. Run `./install.sh` from there.
4. Open a new terminal.

`install.sh` does three things, each skipped if already done:

1. Installs the seven tools in the `Brewfile`. It never upgrades anything already
   installed.
2. Links `interactive.zsh` and `extras.zsh` into `~/.config/zsh/`.
3. Adds one line per file to the end of `~/.zshrc` to load it. Nothing else in
   `~/.zshrc` is touched.

## The seven tools

| Tool | Why |
|---|---|
| `fzf` | Ctrl-R and Ctrl-T |
| `zsh-autosuggestions` | Suggestions as you type |
| `zsh-syntax-highlighting` | Command colouring |
| `fd` | Lists files for Ctrl-T; the `find` alias |
| `bat` | Previews a file in Ctrl-T; the `cat` alias |
| `ripgrep` | The `grep` alias |
| `eza` | Previews a folder in Ctrl-T; the `ls`, `ll` and `lt` aliases |

## Changing things

The files in `~/.config/zsh/` are links to the ones in this repo, so edits are
live in the next terminal and show up in `git diff` here. The link points at
wherever you cloned the repo, so if you move or rename that folder, run
`./install.sh` again to fix it.

## Optional, not installed

Files in `optional/` are kept here but `install.sh` ignores them: nothing links
or loads them automatically.

- **`optional/remote.zsh`:** `code-remote` opens a folder on a machine you reach
  over SSH in VS Code; `claude-remote` starts Claude there inside tmux, so it
  survives disconnects. Both tab-complete folder names from that machine.

To use it, link it and load it from `~/.zshrc` yourself, after the
`interactive.zsh` line, with your own host and username:

```sh
ln -s "$PWD/optional/remote.zsh" ~/.config/zsh/remote.zsh
cat >> ~/.zshrc <<'ZSH'
REMOTE_HOST=myserver REMOTE_USER=user
[ -f ~/.config/zsh/remote.zsh ] && source ~/.config/zsh/remote.zsh
ZSH
```

## Not in here

Everything else on the Mac: the rest of `~/.zshrc` (aliases, PATH, helper
functions), other dotfiles, git settings, apps, and their settings.
