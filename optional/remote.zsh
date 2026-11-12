# Helpers for a remote machine you reach over SSH: open a folder there in
# VS Code, or start Claude there inside tmux. Not loaded by install.sh.
#
# Set these before sourcing this file (for example in ~/.zshrc):
#   REMOTE_HOST=myserver        # a Host name from ~/.ssh/config
#   REMOTE_USER=user            # your username on that machine
#   REMOTE_VSCODE_PROFILE=work  # optional: VS Code profile to open with
#
# Paths you pass are relative to the remote home folder (/home/$REMOTE_USER).

: ${REMOTE_HOST:=remote}
: ${REMOTE_USER:=user}

# Open a folder on the remote machine in VS Code
code-remote() {
  local -a profile
  [[ -n $REMOTE_VSCODE_PROFILE ]] && profile=(--profile "$REMOTE_VSCODE_PROFILE")
  code $profile --remote "ssh-remote+$REMOTE_HOST" "/home/$REMOTE_USER/${1#/}"
}

# Tab-complete with folder names from the remote machine
_remote_dirs() {
  local typed=${PREFIX#/} lead= dir=
  [[ $PREFIX == /* ]] && lead=/
  [[ $typed == */* ]] && dir=${typed%/*}/
  local -a names
  names=(${(f)"$(ssh -o BatchMode=yes -o ConnectTimeout=3 "$REMOTE_HOST" \
    "find /home/${(q)REMOTE_USER}/${(q)dir} -mindepth 1 -maxdepth 1 -type d -printf '%f\n'" 2>/dev/null)"})
  [[ ${typed##*/} == .* ]] || names=(${names:#.*})
  compadd -p "$lead$dir" -S / -q -- $names
}
compdef _remote_dirs code-remote

# Start Claude in a folder on the remote machine, inside a tmux session named
# after the folder, so it survives disconnects; running it again rejoins.
claude-remote() {
  local dir="/home/$REMOTE_USER/${1#/}"
  local name="${${dir%/}:t}"
  name="${name//[.:]/_}"
  ssh -t "$REMOTE_HOST" "cd ${(q)dir} && exec tmux new-session -A -s ${(q)name} 'exec zsh -lc claude'"
}
compdef _remote_dirs claude-remote
