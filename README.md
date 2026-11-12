# mac-setup

How my terminal behaves, without oh-my-zsh or powerlevel10k: the prompt, key
bindings, suggestions, highlighting and fuzzy finder, plus two small commands.
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

`extras.zsh` holds two commands:

- **`reload`** restarts the shell, so config changes take effect.
- **`killport`** opens a picker listing the TCP ports your processes are
  listening on, plus your orphaned processes that hold no port. Type to filter,
  Tab to mark several, Enter to stop them, Esc to leave. Piped, it prints the
  list instead.

## Install

1. Install [Homebrew](https://brew.sh).
2. Clone this repo anywhere you like and go into it.
3. Run `./install.sh` from there.
4. Open a new terminal.

`install.sh` does three things, each skipped if already done:

1. Installs the six tools in the `Brewfile`. It never upgrades anything already
   installed.
2. Links `interactive.zsh` and `extras.zsh` into `~/.config/zsh/`.
3. Adds one line per file to the end of `~/.zshrc` to load it. Nothing else in
   `~/.zshrc` is touched.

If your `~/.zshrc` has aliases that redefine `grep` or `find`, move that line
above them.

## The six tools

| Tool | Why |
|---|---|
| `fzf` | Ctrl-R and Ctrl-T |
| `zsh-autosuggestions` | Suggestions as you type |
| `zsh-syntax-highlighting` | Command colouring |
| `fd` | Lists files for Ctrl-T |
| `bat` | Previews a file in Ctrl-T |
| `eza` | Previews a folder in Ctrl-T |

## Changing things

The files in `~/.config/zsh/` are links to the ones in this repo, so edits are
live in the next terminal and show up in `git diff` here. The link points at
wherever you cloned the repo, so if you move or rename that folder, run
`./install.sh` again to fix it.

## Not in here

Everything else on the Mac: the rest of `~/.zshrc` (aliases, PATH, helper
functions), other dotfiles, git settings, apps, and their settings.
