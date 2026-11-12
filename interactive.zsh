# Interactive shell setup: prompt, options, history search, fzf, typing aids.
# Sourced from ~/.zshrc. Needs Homebrew's bin folder on PATH, and should come
# before any aliases that redefine grep or find (so the scripts sourced below
# are parsed with the real commands).

# Prompt: current dir in cyan, then ❯ on its own line, green/red by last exit status
_prompt_full=$'%F{cyan}%~%f\n%(?.%F{green}.%F{red})❯%f '
_prompt_short='%(?.%F{green}.%F{red})❯%f '
PROMPT=$_prompt_full

# Transient prompt: when a command is entered, its prompt collapses to a bare ❯,
# so only the current prompt shows the directory. precmd puts the full one back.
# Only on the first line ($CONTEXT == start): redrawing a continuation line
# would re-expand its `for>` / `quote>` label with stale parser state.
_prompt_collapse() { [[ $CONTEXT == start ]] || return 0; PROMPT=$_prompt_short; zle reset-prompt }
_prompt_restore() { PROMPT=$_prompt_full }
autoload -Uz add-zle-hook-widget add-zsh-hook
add-zle-hook-widget line-finish _prompt_collapse
add-zsh-hook precmd _prompt_restore

# Blank line above each prompt, so a command's output and the next prompt don't
# run together. Not before the very first prompt of a new terminal.
_gap_before_prompt() { [[ -n $_gap_started ]] && print; _gap_started=1 }
add-zsh-hook precmd _gap_before_prompt

# Shell behaviour
setopt auto_cd auto_pushd pushd_ignore_dups interactive_comments
# History: shared between open terminals, each command kept once
setopt share_history hist_ignore_all_dups hist_save_no_dups

# Tab completion: start it unless ~/.zshrc already has (it must only start once)
(( $+functions[compdef] )) || { autoload -Uz compinit && compinit }
zstyle ':completion:*' menu select                       # arrow-key menu
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'   # case-insensitive

# Completion menu: file-type colours (folders blue, executables green, links cyan)
# and results grouped under a heading per kind (files, commands, options, ...)
zstyle ':completion:*' list-colors ${(s.:.)${LS_COLORS:-di=1;34:ln=36:so=35:pi=33:ex=1;32}}
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}── %d ──%f'

# Up two / three folders (plain `..` already works through auto_cd)
alias ...='cd ../..'
alias ....='cd ../../..'

# Esc Esc: toggle `sudo` in front of the current line, or the previous command if the line is empty
_sudo_toggle() {
  [[ -z $BUFFER ]] && BUFFER=$(fc -ln -1)
  if [[ $BUFFER == sudo\ * ]]; then BUFFER=${BUFFER#sudo }; else BUFFER="sudo $BUFFER"; fi
  CURSOR=$#BUFFER
}
zle -N _sudo_toggle
bindkey '\e\e' _sudo_toggle

# Up/Down search history by the prefix already typed
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search; zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# Enter on an empty prompt does nothing (no new prompt is drawn).
# $CONTEXT check: inside a multi-line command (for/if/quote), blank lines still go through.
_accept_line_unless_empty() {
  [[ -n ${BUFFER//[[:space:]]/} || $CONTEXT != start ]] && zle .accept-line
}
zle -N accept-line _accept_line_unless_empty

# Fuzzy finder: Ctrl-R history search, Ctrl-T file picker
# Ctrl-T lists through fd (includes dotfiles, skips .git and gitignored files)
# and previews the highlighted entry: bat for files, an eza tree for folders.
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND='fd --hidden --follow --exclude .git'
export FZF_CTRL_T_OPTS="--preview '[[ -d {} ]] && eza --tree --level=2 --color=always {} || bat --color=always --style=numbers --line-range=:200 {}'"
source <(fzf --zsh)

# Typing aids — syntax highlighting must be sourced last of these
source ${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source ${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
