# Helpers for remote machines you reach over SSH: open a folder there in
# VS Code, or start Claude there inside tmux. Not loaded by install.sh.
#
# Both commands ask three things in turn:
#   1. the machine  - the Host entries in ~/.ssh/config
#   2. the username - prefilled with that host's User; Enter accepts it
#   3. the folder   - browse one level at a time, starting in their home:
#                     Enter opens, Right goes in, Left goes up
# Esc or Ctrl-C at any step cancels.

# List the machines named in ~/.ssh/config, skipping patterns like "*"
_remote_hosts() {
  awk 'tolower($1) == "host" { for (i = 2; i <= NF; i++) if ($i !~ /[*?!]/) print $i }' \
    ~/.ssh/config 2>/dev/null | awk '!seen[$0]++'
}

# Show a menu of choices (fzf if installed, else a numbered list); prints the pick
_remote_menu() {
  local prompt=$1 pick; shift
  if (( $+commands[fzf] )); then
    print -l -- "$@" | fzf --height=~40% --reverse --prompt="$prompt> "
  else
    local PROMPT3="$prompt number: "
    select pick in "$@"; do [[ -n $pick ]] && break; done
    [[ -n $pick ]] && print -r -- $pick
  fi
}

# Steps 1 and 2: sets REMOTE_HOST and REMOTE_USER
_remote_pick() {
  local -a hosts
  hosts=(${(f)"$(_remote_hosts)"})
  if (( ! $#hosts )); then
    print -u2 "No machines found in ~/.ssh/config"
    return 1
  fi
  REMOTE_HOST=$(_remote_menu Machine $hosts) && [[ -n $REMOTE_HOST ]] || return 1

  REMOTE_USER=$(ssh -G "$REMOTE_HOST" 2>/dev/null | awk '$1 == "user" { print $2; exit }')
  vared -p 'Username: ' REMOTE_USER && [[ -n $REMOTE_USER ]] || return 1
}

# Reuse one SSH connection for every step when ~/.ssh/config doesn't already
# set that up for this host (a fresh login per folder would be slow)
_remote_ssh_opts() {
  REMOTE_SSH=(-o ConnectTimeout=5)
  ssh -G "$REMOTE_USER@$REMOTE_HOST" 2>/dev/null | grep -qx 'controlmaster false' &&
    REMOTE_SSH+=(-o ControlMaster=auto -o 'ControlPath=~/.ssh/remote-%C' -o ControlPersist=60)
  return 0
}

# List the folders inside a remote folder (empty = home). The first line of
# output is that folder's full path; hidden folders are skipped.
_remote_ls() {
  ssh -n $REMOTE_SSH "$REMOTE_USER@$REMOTE_HOST" \
    "cd ${1:+-- ${(q)1}} && pwd && find . -mindepth 1 -maxdepth 1 -type d ! -name '.*'" 2>/dev/null
}

# Step 3: browse one level at a time; sets REMOTE_DIR to the chosen folder.
#   Enter  open the highlighted folder ("./" is the folder you're in)
#   Right  go into the highlighted folder
#   Left   go up to the parent folder
#   Esc    cancel
_remote_pick_dir() {
  local cur= home= key pick
  local -a lines dirs
  while true; do
    lines=(${(f)"$(_remote_ls "$cur")"})
    if (( ! $#lines )); then
      [[ -z $home ]] && { print -u2 "Couldn't log in to $REMOTE_HOST as $REMOTE_USER"; return 1 }
      print -u2 "Can't open $cur"
      cur=$prev
      continue
    fi
    cur=$lines[1]
    [[ -n $home ]] || home=$cur
    dirs=(${(o)${lines[2,-1]#./}/%//})   # ./go -> go/
    local shown=${cur/#$home/\~}

    if (( $+commands[fzf] )); then
      lines=("${(@f)$(print -l -- ./ $dirs | fzf --height=~50% --reverse \
        --border=rounded --border-label=" $REMOTE_HOST:$shown " --info=hidden \
        --prompt='Folder> ' --header='enter open · → go in · ← go up · esc cancel' \
        --bind=enter:accept-non-empty --expect=left,right)}") || return 1
      key=$lines[1] pick=$lines[2]
    else
      local PROMPT3="$REMOTE_HOST:$shown  number: "
      pick=
      select pick in './ (open this folder)' '../ (go up)' $dirs; do [[ -n $pick ]] && break; done
      [[ -n $pick ]] || return 1
      case $pick in
        ./*)  key= pick=./ ;;
        ../*) key=left ;;
        *)    key=right ;;
      esac
    fi

    local prev=$cur
    case $key in
      left)  cur=${cur:h} ;;
      right) [[ $pick == ./ ]] || cur=$cur/${pick%/} ;;
      *)     REMOTE_DIR=$cur${${pick:#./}:+/${pick%/}}; return 0 ;;
    esac
  done
}

# Open a folder on a remote machine in VS Code, using the "remote" profile
code-remote() {
  local REMOTE_HOST REMOTE_USER REMOTE_DIR
  local -a REMOTE_SSH
  _remote_pick && _remote_ssh_opts && _remote_pick_dir || return
  code --profile remote --remote "ssh-remote+$REMOTE_USER@$REMOTE_HOST" "$REMOTE_DIR"
}

# Start Claude in a folder on a remote machine, inside a tmux session named
# after the folder, so it survives disconnects; running it again rejoins.
claude-remote() {
  local REMOTE_HOST REMOTE_USER REMOTE_DIR
  local -a REMOTE_SSH
  _remote_pick && _remote_ssh_opts && _remote_pick_dir || return
  local name=${${REMOTE_DIR:t}//[.:]/_}
  ssh -t $REMOTE_SSH "$REMOTE_USER@$REMOTE_HOST" "cd ${(q)REMOTE_DIR} && exec tmux new-session -A -s ${(q)name} 'exec zsh -lc claude'"
}
